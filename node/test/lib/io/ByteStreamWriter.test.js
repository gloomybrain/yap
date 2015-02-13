describe('ByteStreamWriter', function()
{
    var ByteStreamWriter = require('../../../lib/io/ByteStreamWriter');
    var writer;

    beforeEach(function()
    {
        writer = new ByteStreamWriter();
    });

    describe('#writeBoolean', function()
    {
        it('should increment length by 1', function()
        {
            writer.length().should.be.equal(0);
            writer.writeBoolean(true);
            writer.length().should.be.equal(1);
        });

        it('should write UInt8 to the underlying buffer', function()
        {
            var writer = new ByteStreamWriter();

            writer.writeBoolean(true);
            writer.writeBoolean(false);

            var buffer = writer.getBuffer();

            buffer.readUInt8(0).should.be.equal(1);
            buffer.readUInt8(1).should.be.equal(0);
        });
    });

    describe('#writeByte', function()
    {
        it('should increment length by 1', function()
        {
            writer.length().should.be.equal(0);
            writer.writeByte(-123);
            writer.length().should.be.equal(1);
        });

        it('should write Int8 to the underlying buffer', function()
        {
            var writer = new ByteStreamWriter();

            writer.writeByte(-123);
            writer.writeByte(123);

            var buffer = writer.getBuffer();

            buffer.readInt8(0).should.be.equal(-123);
            buffer.readInt8(1).should.be.equal(123);
        });
    });

    describe('#writeInt', function()
    {
        it('should increment length by 4', function()
        {
            writer.length().should.be.equal(0);
            writer.writeInt(1024);
            writer.length().should.be.equal(4);
        });

        it('should write Int32BE to the underlying buffer', function()
        {
            var writer = new ByteStreamWriter();

            writer.writeInt(-1024);
            writer.writeInt(1024);

            var buffer = writer.getBuffer();

            buffer.readInt32BE(0).should.be.equal(-1024);
            buffer.readInt32BE(4).should.be.equal(1024);
        });
    });

    describe('#writeDouble', function()
    {
        it('should increment length by 8', function()
        {
            writer.length().should.be.equal(0);
            writer.writeDouble(1024.768);
            writer.length().should.be.equal(8);
        });

        it('should write DoubleBE to the underlying buffer', function()
        {
            var writer = new ByteStreamWriter();

            writer.writeDouble(-1024.768);
            writer.writeDouble(1024.768);

            var buffer = writer.getBuffer();

            buffer.readDoubleBE(0).should.be.equal(-1024.768);
            buffer.readDoubleBE(8).should.be.equal(1024.768);
        });
    });

    describe('#writeUTFBytes', function()
    {
        it('should increment length by given string length', function()
        {
            var str = 'Hello world!';
            var len = Buffer.byteLength(str);

            writer.writeUTFBytes(str);
            writer.length().should.be.equal(len);
        });

        it('should write UTF-8 string to the underlying buffer', function()
        {
            var writer = new ByteStreamWriter();
            writer.writeUTFBytes('Hello world!');
            var buffer = writer.getBuffer();

            buffer.toString('utf8', 0, buffer.length).should.be.equal('Hello world!');
        });
    });

    describe('#writeBuffer', function()
    {
        it('should increment length by given buffer length', function()
        {
            var buffer = new Buffer(100);
            writer.writeBuffer(buffer);

            writer.length().should.be.equal(100);
        });

        it('should be unsafe by default', function()
        {
            var writer = new ByteStreamWriter();
            var buffer = new Buffer(8);

            buffer.writeDoubleBE(1024.768, 0);

            writer.writeBuffer(buffer);

            buffer.writeDoubleBE(640.480, 0);

            var result = writer.getBuffer();

            result.readDoubleBE(0).should.be.equal(640.480);
        });

        it('should be safe if desired', function()
        {
            var writer = new ByteStreamWriter();
            var buffer = new Buffer(8);

            buffer.writeDoubleBE(1024.768, 0);

            writer.writeBuffer(buffer, true);

            buffer.writeDoubleBE(640.480, 0);

            var result = writer.getBuffer();

            result.readDoubleBE(0).should.be.equal(1024.768, 0);
        });
    });

    describe('#getBuffer', function()
    {
        it('should return a buffer of corresponding length', function()
        {
            writer.writeBoolean(true);          // 1
            writer.writeByte(123);              // 1
            writer.writeInt(1024);              // 4
            writer.writeDouble(123.321);        // 8
            writer.writeUTFBytes('1234567');    // 7
            writer.writeBuffer(new Buffer(10)); // 10

            var len = writer.length();

            writer.getBuffer().length.should.be.equal(len);
        });

        it('should return a unique buffer each time', function()
        {
            var b1 = writer.getBuffer();
            var b2 = writer.getBuffer();

            b1.should.not.be.equal(b2);
        });

        it('should return independant buffer', function()
        {
            var writer = new ByteStreamWriter();
            var buffer = new Buffer(8);

            buffer.writeDoubleBE(123.321, 0);
            writer.writeBuffer(buffer, false);

            var result = writer.getBuffer();

            buffer.writeDoubleBE(321.123, 0);

            result.readDoubleBE(0).should.be.equal(123.321);
        });
    });

    describe('#length', function()
    {
        it('should return underlying buffer length', function()
        {
            var str = "Hello world!";
            var len = Buffer.byteLength(str, 'utf8');

            writer.length().should.be.equal(0);
            writer.writeUTFBytes(str);
            writer.length().should.be.equal(len);
        });
    });
});
