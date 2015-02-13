require 'bindata'

require_relative 'pascal_string.rb'
require_relative 'exchangable.rb'
require_relative 'apply_commands_message.rb'
require_relative 'apply_script_message.rb'
require_relative 'apply_commands_response.rb'


# Base package class of SharedLogic binary protocol. 
# Format description is avaliable at http://git.burlutskiy.me/demo_clash/wikis/home
class Package < BinData::Record
  endian :big
  
  uint32 :len, value: lambda { 1 + message.num_bytes }
  uint8 :type, initial_value: 0

  choice :message, read_length: :len, selection: :type, :onlyif => :has_message? do
    virtual 0
    apply_commands_message 1
    apply_commands_success_response 2
    apply_commands_error_response 3
    apply_script_message 4
    pascal_string 5 # apply_script_success_response 5
    pascal_string 6 # apply_script_error_response 6
  end

  def has_message?
    len > 1
  end

  def error?
    return type == 3 || type == 6
  end
end
