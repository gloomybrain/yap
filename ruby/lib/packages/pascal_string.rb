require 'bindata'

# The often used pattern for storing strings in binary data.
# First 4 bytes  are the length of string (N), then N bytes are the string itself.
class PascalString < BinData::Primitive
  uint32be :len, :value => lambda { data.length }
  string :data, :read_length => :len

  def get;   self.data; end
  def set(v) self.data = v; end
end
