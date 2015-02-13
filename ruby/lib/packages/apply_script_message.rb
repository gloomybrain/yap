require 'bindata'

# Message of apply script package.
# http://git.burlutskiy.me/demo_clash/wikis/apply_script-message
class ApplyScriptMessage < BinData::Record
  pascal_string :script_name
  pascal_string :dump
  pascal_string :report
end
