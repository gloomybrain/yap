describe('RawPacket', function()
{
    var RawPacket = require('../../../lib/io/RawPacket');
    
    it('should have type property of type Number', function()
    {
        var packet = new RawPacket(0, new Buffer(10));
        packet.should.have.ownProperty('type').equal(0);
    });

    it('should have data property of type Buffer', function()
    {
        var packet = new RawPacket(0, new Buffer(10));
        packet.should.have.ownProperty('data').instanceof(Buffer);
    });
});
