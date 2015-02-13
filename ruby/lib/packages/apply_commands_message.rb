require 'bindata'

# Message of apply batch package.
# Description is avaliable at http://git.burlutskiy.me/demo_clash/wikis/apply_commands-message
class ApplyCommandsMessage < BinData::Record
  pascal_string :logic_version
  pascal_string :dump
  pascal_string :batch

  uint32be :num_exchangables, value: lambda { exchangables.size }
  array :exchangables, :type => :exchangable, initial_length: :num_exchangables
end
