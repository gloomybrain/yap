describe('writeErrorResponse', function()
{
    var ByteStreamWriter = require('../../../lib/io/ByteStreamWriter');
    var ByteStreamReader = require('../../../lib/io/ByteStreamReader');
    var writeErrorResponse = require('../../../lib/packets/writeErrorResponse');

    it('should work as expected =)', function()
    {
        var error = 'Hey, I am an error!';
        var errorLength = Buffer.byteLength(error, 'utf8');
        var writer = new ByteStreamWriter();

        var resultWriter = writeErrorResponse(error, writer);
        var buffer = resultWriter.getBuffer();
        var reader = new ByteStreamReader(buffer);

        resultWriter.should.be.equal(writer);
        reader.readInt().should.be.equal(errorLength + 8);
        reader.readInt().should.be.equal(3); // тип error_response
        reader.readInt().should.be.equal(errorLength);
        reader.readUTFBytes(errorLength).should.be.equal(error);
    });
});