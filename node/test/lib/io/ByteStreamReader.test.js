describe('ByteStreamReader', function()
{
    var ByteStreamReader = require('../../../lib/io/ByteStreamReader');
    var buffer;

    beforeEach(function()
    {
        buffer = new Buffer(100);
    });

    describe('#constructor', function()
    {
        it('should consume nothing but buffer as the first parameter', function()
        {
            (function(){
                var reader = new ByteStreamReader();
            }).should.throw();

            (function(){
                var reader = new ByteStreamReader('some string');
            }).should.throw();

            (function(){
                var reader = new ByteStreamReader(buffer);
            }).should.not.throw();
        });

        it('should not copy consumed buffer, if not safe', function()
        {
            var reader = new ByteStreamReader(buffer, false);

            buffer.writeInt32BE(123, 0);
            reader.readInt().should.be.equal(123);

            reader.position(0);

            buffer.writeInt32BE(321, 0);
            reader.readInt().should.be.equal(321);
        });

        it('should copy consumed buffer, if safe', function()
        {
            buffer.writeInt32BE(123, 0);

            var reader = new ByteStreamReader(buffer, true);

            reader.readInt().should.be.equal(123);

            reader.position(0);

            buffer.writeInt32BE(321, 0);
            reader.readInt().should.be.equal(123);
        });

        it('should be not safe by default', function()
        {
            var reader = new ByteStreamReader(buffer);

            buffer.writeInt32BE(123, 0);
            reader.readInt().should.be.equal(123);

            reader.position(0);

            buffer.writeInt32BE(321, 0);
            reader.readInt().should.be.equal(321);
        });
    });

    describe('#readBoolean', function()
    {
        var reader;

        beforeEach(function()
        {
            reader = new ByteStreamReader(buffer);
        });

        it('should check bytesAvailable', function()
        {
            reader.position(100);
            (function(){ reader.readBoolean(); }).should.throw();

            reader.position(99);
            (function(){ reader.readBoolean(); }).should.not.throw();
        });

        it('should move position by 1', function()
        {
            reader.position(53);
            reader.readBoolean();
            reader.position().should.be.equal(54);
        });

        it('should return a boolean', function()
        {
            buffer.writeUInt8(1, 0);
            (typeof(reader.readBoolean())).should.be.equal('boolean');

            buffer.writeUInt8(123, 0);
            (typeof(reader.readBoolean())).should.be.equal('boolean');

            buffer.writeUInt8(0, 0);
            (typeof(reader.readBoolean())).should.be.equal('boolean');
        });

        it('should read 0 as false and anything else as true', function()
        {
            buffer.writeUInt8(0, 0);
            reader.readBoolean().should.be.false;

            reader.position(0);

            buffer.writeUInt8(1, 0);
            reader.readBoolean().should.be.true;

            reader.position(0);

            buffer.writeUInt8(123, 0);
            reader.readBoolean().should.be.true;
        });
    });

    describe('#readByte', function()
    {
        var reader;
        
        beforeEach(function()
        {
            reader = new ByteStreamReader(buffer);
        });

        it('should check bytesAvailable', function()
        {
            reader.position(100);
            (function(){ reader.readByte(); }).should.throw();

            reader.position(99);
            (function(){ reader.readByte(); }).should.not.throw();
        });

        it('should move position by 1', function()
        {
            reader.position(53);
            reader.readByte();
            reader.position().should.be.equal(54);
        });

        it('should read correct values', function()
        {
            buffer.writeInt8(123, 0);
            buffer.writeInt8(-123, 1);

            reader.readByte().should.be.equal(123);
            reader.readByte().should.be.equal(-123);
        });
    });

    describe('#readInt', function()
    {
        var reader;
        
        beforeEach(function()
        {
            reader = new ByteStreamReader(buffer);
        });

        it('should check bytesAvailable', function()
        {
            reader.position(100);
            (function(){ reader.readInt(); }).should.throw();

            reader.position(96);
            (function(){ reader.readInt(); }).should.not.throw();
        });

        it('should move position by 4', function()
        {
            reader.position(53);
            reader.readInt();
            reader.position().should.be.equal(57);
        });

        it('should read correct values', function()
        {
            buffer.writeInt32BE(1024, 0);
            buffer.writeInt32BE(-768, 4);

            reader.readInt().should.be.equal(1024);
            reader.readInt().should.be.equal(-768);
        });
    });

    describe('#readDouble', function()
    {
        var reader;
        
        beforeEach(function()
        {
            reader = new ByteStreamReader(buffer);
        });

        it('should check bytesAvailable', function()
        {
            reader.position(100);
            (function(){ reader.readDouble(); }).should.throw();

            reader.position(92);
            (function(){ reader.readDouble(); }).should.not.throw();
        });

        it('should move position by 8', function()
        {
            reader.position(53);
            reader.readDouble();
            reader.position().should.be.equal(61);
        });

        it('should read correct values', function()
        {
            buffer.writeDoubleBE(1024.768, 0);
            buffer.writeDoubleBE(-768.1024, 8);

            reader.readDouble().should.be.equal(1024.768);
            reader.readDouble().should.be.equal(-768.1024);
        });
    });

    describe('#readUTFBytes', function()
    {
        var reader;
        
        beforeEach(function()
        {
            reader = new ByteStreamReader(buffer);
        });

        it('should check bytesAvailable', function()
        {
            reader.position(100);
            (function(){ reader.readUTFBytes(10); }).should.throw();

            reader.position(90);
            (function(){ reader.readUTFBytes(10); }).should.not.throw();
        });

        it('should move position by byte-length of the string', function()
        {
            reader.position(53);
            reader.readUTFBytes(47);
            reader.position().should.be.equal(100);
        });

        it('should read correct values', function()
        {
            var str = 'Hello world!';
            var len = Buffer.byteLength(str, 'utf8');

            buffer.write(str, 0, len, 'utf8');

            reader.readUTFBytes(len).should.be.equal(str);
        });
    });

    describe('#readBuffer', function()
    {
        var reader;
        
        beforeEach(function()
        {
            reader = new ByteStreamReader(buffer);
        });

        it('should check bytesAvailable', function()
        {
            reader.position(100);
            (function(){ reader.readBuffer(10); }).should.throw();

            reader.position(90);
            (function(){ reader.readBuffer(10); }).should.not.throw();
        });

        it('should move position by the given length', function()
        {
            reader.position(53);
            reader.readBuffer(47);
            reader.position().should.be.equal(100);
        });

        it('should be unsafe by default', function()
        {
            buffer.writeDoubleBE(0.123, 0);

            var copy = reader.readBuffer(8);
            copy.readDoubleBE(0).should.be.equal(0.123);

            buffer.writeDoubleBE(0.321, 0);
            copy.readDoubleBE(0).should.be.equal(0.321);
        });

        it('should be safe if desirable', function()
        {
            buffer.writeDoubleBE(0.123, 0);

            var copy = reader.readBuffer(8, true);
            copy.readDoubleBE(0).should.be.equal(0.123);

            buffer.writeDoubleBE(0.321, 0);
            copy.readDoubleBE(0).should.be.equal(0.123);
        });
    });

    describe('#bytesAvailable', function()
    {
        it('should return actual bytes available to read', function()
        {
            var reader = new ByteStreamReader(buffer);
            reader.bytesAvailable().should.be.equal(100);

            reader.position(50);

            reader.bytesAvailable().should.be.equal(50);
        });
    });

    describe('#position', function()
    {
        var reader;

        beforeEach(function()
        {
            reader = new ByteStreamReader(buffer);
        });

        it('should return actual position', function()
        {
            reader.position().should.be.equal(0);

            reader.readBuffer(32);
            reader.position().should.be.equal(32);
        });

        it('should throw on invalid set', function()
        {
            (function(){ reader.position(-1); }).should.throw();
            (function(){ reader.position(101); }).should.throw();
        });

        it('should change position on set', function()
        {
            reader.position(21);
            reader.position().should.be.equal(21);
        });
    });
});
