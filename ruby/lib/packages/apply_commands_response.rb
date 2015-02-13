require 'bindata'

class UsedExchangable < BinData::Record
  pascal_string :name
  uint32be :id
end

class CreatedExchangable < BinData::Record
  pascal_string :name
  pascal_string :shared_params
  pascal_string :server_params
end

# Результат выполнения батча.
# Описание http://git.burlutskiy.me/demo_clash/wikis/apply_commands_response-message
class ApplyCommandsSuccessResponse < BinData::Record
  pascal_string :new_dump
  
  uint32be :num_used_exchangables, value: lambda { used_exchangables.size }
  array :used_exchangables, initial_length: :num_used_exchangables, type: :used_exchangable

  uint32be :num_created_exchangables, value: lambda { created_exchangables.size }
  array :created_exchangables, initial_length: :num_created_exchangables, type: :created_exchangable
end

class ApplyCommandsErrorResponse < PascalString; end
