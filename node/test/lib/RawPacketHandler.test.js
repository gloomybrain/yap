describe('RawPacketHandler', function()
{
    var RawPacketHandler = require('../../lib/RawPacketHandler');
    var RawPacket = require('../../lib/io/RawPacket');
    var ByteStreamReader = require('../../lib/io/ByteStreamReader');
    var ByteStreamWriter = require('../../lib/io/ByteStreamWriter');

    describe('#constructor', function()
    {
        it('should work', function()
        {
            (function(){
                new RawPacketHandler();
            }).should.not.throw();
        });
    });

    describe('#setHandlerForType', function()
    {
        it('should exist', function()
        {
            var handler = new RawPacketHandler();

            handler.should.have.ownProperty('setHandlerForType');
            handler['setHandlerForType'].should.be.type('function');
        });

        it('should only consume handlers with existing handle method', function()
        {
            var handler = new RawPacketHandler();

            (function()
            {
                handler.setHandlerForType(null, 0)
            }).should.throw();

            (function()
            {
                handler.setHandlerForType({}, 0)
            }).should.throw();

            (function()
            {
                handler.setHandlerForType({handle: null}, 0)
            }).should.throw();

            (function()
            {
                handler.setHandlerForType({handle: function(){}}, 0)
            }).should.not.throw();
        });

        it('should only consume handler with integer types', function()
        {
            var handler = new RawPacketHandler();

            (function()
            {
                handler.setHandlerForType({handle: function(){}}, true)
            }).should.throw();

            (function()
            {
                handler.setHandlerForType({handle: function(){}}, 'true')
            }).should.throw();

            (function()
            {
                handler.setHandlerForType({handle: function(){}}, -1.37)
            }).should.throw();

            (function()
            {
                handler.setHandlerForType({handle: function(){}}, 0)
            }).should.not.throw();
        });
    });

    describe('#handle', function()
    {
        it('should exist', function()
        {
            var handler = new RawPacketHandler();

            handler.should.have.ownProperty('handle');
            handler['handle'].should.be.type('function');
        });

        it('should throw on unregistered packet types', function()
        {
            var type = 0;

            (function()
            {
                (new RawPacketHandler()).handle(new RawPacket(type, null));
            }).should.throw('Unable to handle packet with type: ' + type);
        });

        it('should handle registered packet types', function()
        {

            var errorText = 'Dummy error!';
            var outerHandler = new RawPacketHandler();

            var innerHandler = {
                handle: function()
                    {
                        throw new Error(errorText);
                }
            };

            outerHandler.setHandlerForType(innerHandler, 0);

            var packet = new RawPacket(0, new Buffer(0));

            (function()
            {
                outerHandler.handle(packet);
            }).should.throw(errorText);
        });
    });
});
