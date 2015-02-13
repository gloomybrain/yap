function ByteStreamReader(buffer, safe)
{
    if (!(buffer && (buffer instanceof Buffer)))
    {
        throw new Error('buffer must be a valid Buffer instance!');
    }

    var _position = 0;
    var _buffer;

    if (safe)
    {
        _buffer = new Buffer(buffer.length);
        buffer.copy(_buffer, 0, 0, buffer.length);
    }
    else
    {
        _buffer = buffer;
    }

    function assertBytesAvailable(numBytes)
    {
        var available = _buffer.length;
        if (_buffer.length - _position < numBytes)
        {
            throw new Error('Not enough bytes available! Needed: ', numBytes, ', got: ', available);
        }
    }

    this.readBoolean = function()
    {
        assertBytesAvailable(1);

        var value = _buffer.readUInt8(_position);
        _position += 1;

        return (value !== 0);
    };

    this.readByte = function()
    {
        assertBytesAvailable(1);

        var value = _buffer.readInt8(_position);
        _position += 1;

        return value;
    };

    this.readInt = function()
    {
        assertBytesAvailable(4);

        var value = _buffer.readInt32BE(_position);
        _position += 4;

        return value;
    };

    this.readDouble = function()
    {
        assertBytesAvailable(8);

        var value = _buffer.readDoubleBE(_position);
        _position += 8;

        return value;
    };

    this.readUTFBytes = function(numBytes)
    {
        assertBytesAvailable(numBytes);

        var value = _buffer.toString('utf8', _position, _position + numBytes);
        _position += numBytes;

        return value;
    };

    this.readBuffer = function(numBytes, safe)
    {
        assertBytesAvailable(numBytes);

        var value;

        if (safe)
        {
            value = new Buffer(numBytes);
            _buffer.copy(value, 0, _position, _position + numBytes);
        }
        else
        {
            value = _buffer.slice(_position, _position + numBytes);
        }

        _position += numBytes;

        return value;
    };

    this.bytesAvailable = function()
    {
        return (_buffer.length - _position);
    };

    this.position = function(value)
    {
        if (typeof(value) === 'undefined') return _position;

        if (value < 0 || value > buffer.length)
        {
            throw new Error('Position must be in interval [0; ', buffer.length, ']');
        }

        _position = value;
    };
}

module.exports = ByteStreamReader;
