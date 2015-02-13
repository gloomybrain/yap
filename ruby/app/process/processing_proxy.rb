require './lib/packages/package.rb'

class ProcessingProxy
  include Singleton

  def initialize(socket_file = '../test_server.sock')
    # open socket
    FileUtils.rm socket_file if File.exist? socket_file
    server = UNIXServer.open(socket_file) if !File.exist? socket_file
    puts 'socket server started'

    # run the nodejs processor
    cmd = 'node ../node/App.js -s ../test_server.sock -c ../node/node-config.yml'
    Process.spawn(cmd)
    puts 'nodejs spawned'
    
	  @server = server
    @socket = server.accept

    puts 'connection accepted' 	
  end

  def apply_batch(logic_version, dump, batch, exchangables)
    package = Package.new
    package.type = 1
    package.message.logic_version = logic_version    
  	package.message.dump = dump
  	package.message.batch = batch
  	package.message.exchangables = exchangables
  	
    @socket.write package.to_binary_s

  	response = Package.read(@socket)
  	puts 'received: ' + response.inspect

  	response
  end

  def apply_script(script_name, dump, report)
  	package = Package.new
  	package.type = 4
  	package.message.script_name = script_name
  	package.message.dump = dump
  	package.message.report = report

  	@socket.write package.to_binary_s

  	response = Package.read(@socket)
  	puts 'received: ' + response.inspect

  	response
  end
end
