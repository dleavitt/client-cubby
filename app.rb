require "rubygems"
require "securerandom"
require "logger"
require "bundler"
Bundler.require :default, ENV['RACK_ENV'] || :development
require "sinatra/reloader"

root = File.dirname(__FILE__)
LIB_PATH = File.join(root, "lib" "**", "*.rb")
  
# require everything in lib folder
Dir[LIB_PATH].each(&method(:require))

# set env variables from env.yml
envfile = File.join(root, "config", "env.yml")
YAML.load_file(envfile).each { |k,v| ENV[k] = v } if File.exist?(envfile)

$redis = Redis::Namespace.new(:client_cubby, :redis => Redis.new(
  :url      => ENV['REDIS_URL'] || ENV['REDISTOGO_URL'],
  :logger   => Logger.new(STDOUT)
))

ClientCubby::Upload.bucket_name = ENV['BUCKET_NAME']

module ClientCubby
  class App < Sinatra::Base

    # middlewares
    use Rack::PostBodyContentTypeParser
    use Rack::Session::Redis,
      :redis_server => "#{$redis.client.id}/client_cubby:session"
    use Rack::Csrf, :raise => true
    use Rack::RawUpload

    # sinatra extensions
    register Sinatra::Contrib

    configure :development do
      register Sinatra::Reloader
      also_reload LIB_PATH
    end

    # config
    enable :method_override
    set :haml, :escape_html => true

    helpers do
      include Sprockets::Helpers

      def user(name = nil)
        @user ||= User.new(name || session[:username])
      end

      def session_auth?
        user.exists?
      end
    end

    get "/" do
      haml session_auth? ? :files : :login
    end

    post "/login" do
      if User.exists?(params[:username], params[:password])
        user = User.new(params[:username])
        session[:username] = user.name
        redirect to "/"
      else
        # TODO: error message
        haml :login
      end
    end

    post "/logout" do
      session[:username] = nil
      # TODO: delete record in redis
      redirect to "/"
    end

    # require auth
    before "/files*" do
      redirect to "/" unless session_auth?
    end

    get "/files/:id" do
      # TODO: error if no file
      @file = user.find_file(params[:id])
      if request.xhr?
        json @file
      else
        haml :file
      end
    end

    get "/files/:id/download" do
      upload = Upload.new(params[:id], user.find_file(params[:id]))
      redirect to upload.get
    end

    post "/files" do
      file_ids = request.params["files"].map do |file|
        file_id = user.create_file(file[:filename])
        UPLOAD_QUEUE.push :upload => Upload.new(file_id, file: file[:tempfile]),
                          :user => user

        file_id
      end

      request.xhr? ? json(ids: file_ids) : redirect(to "/")
    end

    delete "/files/:id" do
      if user.find_file(params[:id])
        user.delete_file(params[:id])
        Upload.new(params[:id]).delete
      end

      redirect to "/"
    end
  end

  UPLOAD_QUEUE = GirlFriday::WorkQueue.new(:uploads, :size => 6) do |params|
    # TODO: logger
    params[:upload].put
    params[:user].update_file(params[:upload].id, :progress => 1)
  end
end