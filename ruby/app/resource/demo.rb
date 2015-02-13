require 'app/process/processing_proxy.rb'

module Resource
  class Demo < Grape::API
    version 'v1', using: :path

    group 'demo' do
      content_type :json, 'application/json'
      format :json

      get '/' do

      end

      post '/save-dump' do

        #save to file

      end

      get '/demo-dump' do
        filename = "../tmp/dump_#{env['REMOTE_ADDR']}.json"

        if File.exists? filename
          puts 'Found dump at ' + filename
          File.read filename          
        else
          puts 'Not found dump at ' + filename + ', returning default dump'
          File.read 'public/demo_dump.json'          
        end
      end

      post '/apply-commands' do                        
        filename = "../tmp/dump_#{env['REMOTE_ADDR']}.json"

        if File.exists? filename
          dump = File.read filename          
        else
          dump = File.read('public/demo_dump.json')  
        end

        proxy = ProcessingProxy.instance
        result = proxy.apply_batch('Context', dump, params[:commands], [])

        if result.error?
          '{"error":"' + result.message.to_s + '"}'
        else
          File.write(filename, result.message.new_dump)
          puts 'Saved dump ' + filename
          '{}'
        end
      end
    end
  end
end
