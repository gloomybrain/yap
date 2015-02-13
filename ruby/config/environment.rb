require 'json'
require 'logger'
require 'sinatra'
require 'grape'

require 'app/resource/demo'

env = ENV['RACK_ENV'] || 'development'

raise 'Environment not set' if env.nil?
