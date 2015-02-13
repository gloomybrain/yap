function ByteStreamWriter()
{
    var _allocSize = 0;
    var _savedWriters = [];
    var _savedValues = [];



    function _writeBoolean(value, buffer, offset)
    {
        buffer.writeUInt8(value ? 1 : 0, offset);
        return (offset + 1);
    }

    function _writeByte(value, buffer, offset)
    {
        buffer.writeInt8(value, offset);
        return (offset + 1);
    }

    function _writeInt(value, buffer, offset)
    {
        buffer.writeInt32BE(value, offset);
        return (offset + 4);
    }

    function _writeDouble(value, buffer, offset)
    {
        buffer.writeDoubleBE(value, offset);
        return (offset + 8);
    }

    function _writeString(value, buffer, offset)
    {
        var numBytes = Buffer.byteLength(value);
        buffer.write(value, offset, numBytes, 'utf8');
        return (offset + numBytes);
    }

    function _writeBuffer(value, buffer, offset)
    {
        value.copy(buffer, offset, 0, value.length);
        return (offset + value.length);
    }



    this.writeBoolean = function(value)
    {
        _allocSize += 1;
        _savedWriters.push(_writeBoolean);
        _savedValues.push(value);
    };

    this.writeByte = function(value)
    {
        _allocSize += 1;
        _savedWriters.push(_writeByte);
        _savedValues.push(value);
    };

    this.writeInt = function(value)
    {
        _allocSize += 4;
        _savedWriters.push(_writeInt);
        _savedValues.push(value);
    };

    this.writeDouble = function(value)
    {
        _allocSize += 8;
        _savedWriters.push(_writeDouble);
        _savedValues.push(value);
    };

    this.writeUTFBytes = function(value)
    {
        _allocSize += Buffer.byteLength(value, 'utf8');
        _savedWriters.push(_writeString);
        _savedValues.push(value);
    };

    this.writeBuffer = function(value, safe)
    {
        _allocSize += value.length;
        _savedWriters.push(_writeBuffer);

        var clone;
        if (safe)
        {
            clone = new Buffer(value.length);
            value.copy(clone, 0, 0, value.length);
        }
        else
        {
            clone = value.slice(0, value.length);
        }

        _savedValues.push(clone);
    };



    this.getBuffer = function()
    {
        var buffer = new Buffer(_allocSize);
        var offset = 0;

        for (var i = 0; i < _savedWriters.length; i++)
        {
            var writer = _savedWriters[i];
            var value = _savedValues[i];

            offset = writer.call(null, value, buffer, offset);
        }

        return buffer;
    };

    this.length = function()
    {
        return _allocSize;
    };
}

module.exports = ByteStreamWriter;
