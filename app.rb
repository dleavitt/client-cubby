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

    helpers do
      def user(name = nil)
        @user ||= User.new(name || session[:username])
      end

      def session_auth?
        user.exists?
      end

      def http_auth?
        auth = Rack::Auth::Basic::Request.new(request.env)

        if auth.provided? && auth.basic && auth.credentials
          return User.exists?(auth_credentials)
        end

        return false
      end
    end

    get "/" do
      if session_auth?
        haml :files
      else
        haml :login
      end
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

    before("/files*") { redirect "/" unless session_auth? }

    get "/files/:id" do
      # TODO: error if no file
      @file = user.find_file(params[:id])
      haml :file
    end

    get "/files/:id/download" do
      @file = user.find_file(params[:id])
    end

    post "/files" do
      file = request.params["file"]
      file_id = user.create_file(file[:filename])
      UPLOAD_QUEUE.push :file_id  => file_id,
                        :file     => file[:tempfile],
                        :user     => user
      redirect "/"
    end
  end

  UPLOAD_QUEUE = GirlFriday::WorkQueue.new(:uploads, :size => 3) do |params|
    # TODO: logger
    # TODO: content-type of file
    obj = AWS::S3.new.buckets[ENV['BUCKET_NAME']].objects[params[:file_id]]
    obj.write(params[:file])
    obj.acl = :private

    user = User.new("")
    user.update_file(params[:file_id], :progress => 1)
  end
end