var RawPacket = require('./RawPacket.js');

function PacketDivisor()
{
	var _tempBuffer = null;
	var _lengthToRead = 0;
	var _packets = [];

	function parseTempBuffer()
	{
	    if (_lengthToRead == 0)
	    {
	        if (_tempBuffer.length < 4) return;

	        _lengthToRead = _tempBuffer.readUInt32BE(0);

	        _tempBuffer = _tempBuffer.slice(4);

	        parseTempBuffer();
	    }
	    else if (_tempBuffer.length >= _lengthToRead)
	    {
	        var packet = new RawPacket(_tempBuffer.readUInt8(0), _tempBuffer.slice(1, _lengthToRead));
	    	// console.log(RawPacket);

	        _packets.push(packet);

	        _tempBuffer = _tempBuffer.slice(_lengthToRead);
	        _lengthToRead = 0;

	        parseTempBuffer();
	    }
	}

	this.appendBytes = function(buffer)
	{
        if(!buffer || !(buffer instanceof Buffer))
        {
            throw new Error('buffer should be an instance of Buffer!');
        }

		if (_tempBuffer === null || _tempBuffer.length === 0)
    	{
        	_tempBuffer = buffer;
    	}
    	else
    	{
        	_tempBuffer = Buffer.concat([_tempBuffer, buffer]);
    	}

    	parseTempBuffer();

    	var result = _packets;
    	_packets = [];

    	return result;
	};
}

module.exports = PacketDivisor;
