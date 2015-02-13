describe('ApplyCommandsResponse', function ()
{
    var ByteStreamReader = require('../../../lib/io/ByteStreamReader');
    var ByteStreamWriter = require('../../../lib/io/ByteStreamWriter');
    var ApplyCommandsResponse = require('../../../lib/packets/ApplyCommandsResponse');

    describe('#constructor', function()
    {
        it('should throw on empty data and fals-ish error', function()
        {
            (function()
            {
                new ApplyCommandsResponse();
            }).should.throw();
        });

        it('should work with no data & true-ish error', function()
        {
            (function()
            {
                new ApplyCommandsResponse(null, null, null, true);
            }).should.not.throw();
        });

        it('should have "writer" property of type ByteStreamWriter whether there was an error or not', function()
        {
            var r = new ApplyCommandsResponse(null, null, null, true);
            r.should.have.ownProperty('writer');
            r['writer'].should.be.instanceof(ByteStreamWriter);

            r = new ApplyCommandsResponse({}, [], []);
            r.should.have.ownProperty('writer');
            r['writer'].should.be.instanceof(ByteStreamWriter);
        });

        it('should contain the right error message in "writer" when error is present', function()
        {
            var message = 'I am a message!';
            var messageLength = Buffer.byteLength(message, 'utf8');
            var response = new ApplyCommandsResponse(null, null, null, message);
            var writer = response.writer;
            var reader = new ByteStreamReader(writer.getBuffer());

            reader.readInt().should.be.equal(messageLength + 8);
            reader.readInt().should.be.equal(3);
            reader.readInt().should.be.equal(messageLength);
            reader.readUTFBytes(messageLength).should.be.equal(message);
        });

        it('should have the right data in "writer" when no error present', function ()
        {
            var dump = { prop1: 1, prop2: '2' };
            var dumpString = JSON.stringify(dump);
            var dumpStringLength = Buffer.byteLength(dumpString);

            var used = [
                { type: 't', id: 1 },
                { type: 't', id: 2 }
            ];

            var created = [
                { type: 't', sharedParams: { p: 'p' }, serverParams: { sp: 'sp' } },
                { type: 't', sharedParams: { p: 'p' }, serverParams: { sp: 'sp' } }
            ];

            var response = new ApplyCommandsResponse(dump, created, used);
            var writer = response.writer;
            var reader = new ByteStreamReader(writer.getBuffer());

            reader.readInt();
            reader.readInt().should.be.equal(4);
            reader.readInt().should.be.equal(dumpStringLength);

            var readDumpString = reader.readUTFBytes(dumpStringLength);
            var readDump = JSON.parse(readDumpString);
            readDump.should.be.eql(dump);

            reader.readInt().should.be.equal(used.length);

            for (var i = 0; i < used.length; i++)
            {
                var type = used[i].type;
                var typeLength = Buffer.byteLength(type, 'utf8');
                var id = used[i].id;

                reader.readInt().should.be.equal(typeLength);
                reader.readUTFBytes(typeLength).should.be.equal(type);
                reader.readInt().should.be.equal(id);
            }

            reader.readInt().should.be.equal(created.length);
            for (var i = 0; i < created.length; i++)
            {
                var current = created[i];
                var type = current.type;
                var typeLength = Buffer.byteLength(type, 'utf8');
                var sharedParamsLength = Buffer.byteLength(JSON.stringify(current.sharedParams), 'utf8');
                var serverParamsLength = Buffer.byteLength(JSON.stringify(current.serverParams), 'utf8');

                reader.readInt().should.be.equal(typeLength);
                reader.readUTFBytes(typeLength).should.be.equal(type);

                reader.readInt().should.be.equal(sharedParamsLength);
                var sharedParamsString = reader.readUTFBytes(sharedParamsLength);
                JSON.parse(sharedParamsString).should.be.eql(current.sharedParams);

                reader.readInt().should.be.equal(serverParamsLength);
                var serverParamsString = reader.readUTFBytes(serverParamsLength);
                JSON.parse(serverParamsString).should.be.eql(current.serverParams);
            }
        });
    });
});
