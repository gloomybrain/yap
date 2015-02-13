describe('PacketDivisor', function()
{
    var RawPacket = require('../../../lib/io/RawPacket');
    var PacketDivisor = require('../../../lib/io/PacketDivisor');

    describe('#appendBytes', function()
    {
        var divisor = null;
        beforeEach(function()
        {
            divisor = new PacketDivisor();
        });

        it('should throw on invalid buffer', function()
        {
            (function(){ divisor.appendBytes(); }).should.throw();
            (function(){ divisor.appendBytes('some string'); }).should.throw();
            (function(){ divisor.appendBytes(new Buffer(10)); }).should.not.throw();
        });

        it('should return an Array', function()
        {
            var result = divisor.appendBytes(new Buffer(10));
            result.should.be.instanceof(Array);
        });

        it('should result an Array of RawPacket', function()
        {
            var buffer = new Buffer(10);
            buffer.writeUInt32BE(6, 0);

            var result = divisor.appendBytes(buffer);
            result.length.should.be.equal(1);
            result[0].should.be.instanceof(RawPacket);
        });

        it('should skip zero-length packets', function()
        {
            var buffer = new Buffer(8);

            buffer.writeUInt32BE(0, 0);
            buffer.writeUInt32BE(0, 4);

            divisor.appendBytes(buffer).length.should.be.equal(0);
        });

        it('should read 4 bytes of length, one byte of type and copy data to RawPacket', function()
        {
            var buffer = new Buffer(22);
            buffer.writeUInt32BE(6, 0);
            buffer.writeUInt32BE(6, 10);

            var result = divisor.appendBytes(buffer);

            result.length.should.be.equal(2);

            result[0].data.length.should.be.equal(5);
            result[1].data.length.should.be.equal(5);
        });

        it('should handle partial messages', function()
        {
            var buffer = new Buffer(6);
            buffer.fill(0);
            buffer.writeUInt32BE(10, 0);

            divisor.appendBytes(buffer).length.should.be.equal(0);

            buffer = new Buffer(10);
            buffer.fill(0);
            
            var result = divisor.appendBytes(buffer);
            result.length.should.be.equal(1);
            result[0].data.length.should.be.equal(9);

            buffer = new Buffer(12);
            buffer.fill(0);
            buffer.writeUInt8(4, 1);
            buffer.writeUInt32BE(2, 6);

            result = divisor.appendBytes(buffer);
            result.length.should.be.equal(2);

            result[0].data.length.should.be.equal(3);
            result[1].data.length.should.be.equal(1);
        });
    });
});
