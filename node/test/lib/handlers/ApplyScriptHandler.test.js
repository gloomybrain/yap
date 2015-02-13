describe('ApplyScriptHandler', function()
{
    var ApplyScriptHandler = require('../../../lib/handlers/ApplyScriptHandler');
    var ByteStreamReader = require('../../../lib/io/ByteStreamReader');
    var ByteStreamWriter = require('../../../lib/io/ByteStreamWriter');

    describe('#constructor', function()
    {
        it('should not throw', function()
        {
            (function(){
                new ApplyScriptHandler();
            }).should.not.throw();
        });
    });

    describe('#handle', function()
    {
        it('should have metod \'hanlde\'', function()
        {
            var handler = new ApplyScriptHandler();

            handler.should.have.ownProperty('handle');
            handler.handle.should.be.type('function');
        });

        it('should be stupid stub', function()
        {
            var handler = new ApplyScriptHandler();

            var writer = new ByteStreamWriter();
            var reader = new ByteStreamReader(writer.getBuffer());

            writer = handler.handle(reader);
            reader = new ByteStreamReader(writer.getBuffer());

            var message = 'handleScript';
            var messageLength = Buffer.byteLength(message, 'utf8');

            reader.readInt().should.be.equal(messageLength);
            reader.readUTFBytes(messageLength).should.be.equal(message);
        });
    });
});
