$LOAD_PATH << File.expand_path(File.dirname(__FILE__))

require "rubygems"
require "bundler/setup"
require 'config/environment'

class API < Grape::API
  #common helpers
  helpers do
    def logger
      API.logger
    end
  end
  mount Resource::Demo
end

class DemoServer < Sinatra::Base
  get '/' do
	send_file File.join(settings.public_folder, 'index.html')
  end
end

run Rack::Cascade.new [API, DemoServer]
