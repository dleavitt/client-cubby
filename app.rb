require "rubygems"
require "securerandom"
require "logger"
require "bundler"
Bundler.require
require "sinatra/reloader"

root = File.dirname(__FILE__)
# require everything in lib folder
Dir[File.join(root, "lib" "**", "*.rb")].each(&method(:require))

envfile = File.join(root, "config", "env.yml")
YAML.load_file(envfile).each { |k,v| ENV[k] = v } if File.exist?(envfile)

$redis = Redis::Namespace.new(:client_cubby, :redis => Redis.new(
  :url => ENV['REDIS_URL'] || ENV['REDISTOGO_URL'],
  :logger => Logger.new(STDOUT)
))

ClientCubby::Upload.bucket_name = ENV['BUCKET_NAME']

module ClientCubby
  class App < Sinatra::Base

    # middlewares
    use Rack::PostBodyContentTypeParser
    use Rack::Session::Redis,
      :redis_server => "#{$redis.client.id}/client_cubby:session"
    use Rack::Csrf, :raise => true

    # sinatra extensions
    register Sinatra::Contrib
    register Sinatra::Reloader if development?
    also_reload "./lib/**.rb"

    enable :method_override

    helpers do
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
        redirect "/"
      else
        # TODO: error message
        haml :login
      end
    end

    post "/logout" do
      session[:username] = nil
      redirect "/"
    end

    before "/files*" do
      redirect "/" unless session_auth?
    end

    get "/files/:id" do
      # TODO: error if no file
      @file = user.find_file(params[:id])
      haml :file
    end

    get "/files/:id/download" do
      upload = Upload.new(params[:id], user.find_file(params[:id]))
      redirect upload.get
    end

    post "/files" do
      file = request.params["file"]
      file_id = user.create_file(file[:filename])

      UPLOAD_QUEUE.push Upload.new(file_id, :file => file[:tempfile])
      redirect "/"
    end

    delete "/files/:id" do
      if user.find_file(params[:id])
        user.delete_file(params[:id])
        Upload.new(params[:id]).delete
      end

      redirect "/"
    end
  end

  UPLOAD_QUEUE = GirlFriday::WorkQueue.new(:uploads, :size => 3) do |upload|
    # TODO: logger
    upload.put
    user = User.new("")
    user.update_file(upload.id, :progress => 1)
  end
end