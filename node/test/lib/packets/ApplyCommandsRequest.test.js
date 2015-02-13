describe('ApplyCommandsRequest', function ()
{
    var ByteStreamReader = require('../../../lib/io/ByteStreamReader');
    var ByteStreamWriter = require('../../../lib/io/ByteStreamWriter');
    var ApplyCommandsRequest = require('../../../lib/packets/ApplyCommandsRequest');

    describe('#constructor', function ()
    {
        it('should copy all parameters by reference', function()
        {
            var logicVersion = '1';
            var dump = {};
            var commands = [];
            var unusedExchangables = [];
            var error = 'some error';

            var request = new ApplyCommandsRequest(logicVersion, dump, commands, unusedExchangables, error);

            request.logicVersion.should.be.equal(logicVersion);
            request.dump.should.be.equal(dump);
            request.commands.should.be.equal(commands);
            request.unusedExchangables.should.be.equal(unusedExchangables);
            request.error.should.be.equal(error);
        });
    });

    describe('#readFromBuffer', function ()
    {
        it('should exist', function ()
        {
            ApplyCommandsRequest.should.have.ownProperty('readFromBuffer');
            ApplyCommandsRequest['readFromBuffer'].should.be.instanceof(Function);
        });

        it('should throw on invalid buffer', function ()
        {
            (function()
            {
                ApplyCommandsRequest.readFromBuffer(null);
            }).should.throw();
        });

        it('should not throw on invalid data', function ()
        {
            var buf = new Buffer(10);

            (function()
            {
                ApplyCommandsRequest.readFromBuffer(buf);
            }).should.not.throw();
        });

        it('should work on correct data', function ()
        {
            var logicVersion = '1';
            var dump = { prop: { name: 'I am a property!' } };
            var commands = [ { time: 1234, name: 'command 1' }, { time: 12345, name: 'command 2' } ];
            var unusedExchangables = [{
                type: 't',
                id: 1,
                sharedParams: { type: 'p' },
                serverParams: { type: 'sp' }
            }];

            var writer = new ByteStreamWriter();

            writer.writeInt(Buffer.byteLength(logicVersion, 'utf8'));
            writer.writeUTFBytes(logicVersion);

            writer.writeInt(Buffer.byteLength(JSON.stringify(dump), 'utf8'));
            writer.writeUTFBytes(JSON.stringify(dump));

            writer.writeInt(Buffer.byteLength(JSON.stringify(commands), 'utf8'));
            writer.writeUTFBytes(JSON.stringify(commands));

            writer.writeInt(unusedExchangables.length);

            for (var i = 0; i < unusedExchangables.length; i++)
            {
                var current = unusedExchangables[i];

                writer.writeInt(Buffer.byteLength(current.type, 'utf8'));
                writer.writeUTFBytes(current.type);

                writer.writeInt(current.id);

                writer.writeInt(Buffer.byteLength(JSON.stringify(current.sharedParams), 'utf8'));
                writer.writeUTFBytes(JSON.stringify(current.sharedParams));

                writer.writeInt(Buffer.byteLength(JSON.stringify(current.serverParams), 'utf8'));
                writer.writeUTFBytes(JSON.stringify(current.serverParams));
            }


            var buffer = writer.getBuffer();

            var request = null;

            (function()
            {
                request = ApplyCommandsRequest.readFromBuffer(buffer);
            }).should.not.throw();

            request.logicVersion.should.be.equal(logicVersion);
            request.dump.should.be.eql(dump);
            request.commands.should.be.eql(commands);
            request.unusedExchangables.should.be.eql(unusedExchangables);
        });
    });
});