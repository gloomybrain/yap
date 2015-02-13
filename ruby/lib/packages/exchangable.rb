# For more about the format see http://git.burlutskiy.me/demo_clash/wikis/apply_commands-message
class Exchangable < BinData::Record
  pascal_string :name
  uint32be :id
  pascal_string :shared_params
  pascal_string :server_params
end
