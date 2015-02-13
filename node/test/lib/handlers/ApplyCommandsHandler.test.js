var ApplyCommandsHandler = require('../../../lib/handlers/ApplyCommandsHandler');
var ByteStreamReader = require('../../../lib/io/ByteStreamReader');
var ByteStreamWriter = require('../../../lib/io/ByteStreamWriter');

describe('ApplyCommandsHandler', function()
{
    describe('#constructor', function()
    {
        it('should throw on invalid config', function()
        {
            (function ()
            {
                new ApplyCommandsHandler();
            }).should.throw('Передан невалидный конфиг!');

            (function ()
            {
                new ApplyCommandsHandler(null);
            }).should.throw('Передан невалидный конфиг!');

            (function ()
            {
                new ApplyCommandsHandler({});
            }).should.throw('Передан невалидный конфиг!');

            (function ()
            {
                new ApplyCommandsHandler({
                    logicPath: './',
                    defaultVersion: './',
                    allowedExchangables: [],
                    allowedActions: []
                });
            }).should.not.throw();
        });
    });

    describe('#handle', function()
    {
        var fs = require('fs');
        var path = require('path');

        function getConfig(logicPath)
        {
            return {
                logicPath: logicPath,
                defaultVersion: 'default',
                allowedExchangables: [],
                allowedActions: []
            }
        }

        function removeContextFile(config, versionName)
        {
            var filePath = path.join(config['logicPath'], versionName + '.js');

            if (fs.existsSync(filePath)) fs.unlinkSync(filePath);
        }

        function createContextFile(config, versionName)
        {
            var text = 'function Context(environment)' +
                '{' +
                    'var _dump;' +
                    'this.setDump = function(dump)' +
                    '{' +
                        '_dump = dump;' +
                    '};' +
                    'this.getDump = function()' +
                    '{' +
                        'return _dump;' +
                    '};' +
                    'this.execute = function(name, params)' +
                    '{' +
                        'if (name == \'example\')' +
                        '{' +
                            '_dump.x = 10;' +
                            'return {' +
                                'dump: _dump, ' +
                                'actions: [], ' +
                                'stateDiff: {}, ' +
                                'exchangables: {' +
                                    'created: [], ' +
                                    'used: []' +
                                '}, ' +
                                'error: null' +
                            '};' +
                        '}' +
                        'else' +
                        '{' +
                            'return {' +
                                'dump: _dump, ' +
                                'actions: [], ' +
                                'stateDiff: {}, ' +
                                'exchangables: {' +
                                    'used:[], ' +
                                    'created: []' +
                                '}, ' +
                                'error: \'Holy cow!\'' +
                            '};' +
                        '}' +
                    '};' +
                '}' +
                'exports.Context = Context;';


            var filePath = path.join(config['logicPath'], versionName + '.js');

            if (fs.existsSync(filePath)) fs.unlinkSync(filePath);
            fs.writeFileSync(filePath, text);
        }

        it('should not throw on invalid data', function()
        {
            (function()
            {
                new ApplyCommandsHandler({
                    logicPath: './',
                    defaultVersion: './',
                    allowedExchangables: [],
                    allowedActions: []
                }).handle(new Buffer('blah-blah-blah'));
            }).should.not.throw();
        });

        it('should return an error_response packet on invalid data', function()
        {
            var writer = new ApplyCommandsHandler(
                getConfig('./')
            ).handle(new Buffer('blah-blah-blah'));

            var reader = new ByteStreamReader(writer.getBuffer());
            reader.readInt(); // пропускаем длину, нам она не важна
            reader.readInt().should.be.equal(3); // error_response
        });

        it('should return an error_response on invalid commands', function()
        {
            var logicPath = path.normalize(__dirname);
            var logicName = 'default';
            var config = getConfig(logicPath);

            createContextFile(config, logicName);

            var handler = new ApplyCommandsHandler(config);

            var writer = new ByteStreamWriter();
            writer.writeInt(Buffer.byteLength(logicName, 'utf8'));
            writer.writeUTFBytes(logicName);
            writer.writeInt(Buffer.byteLength('{}'));
            writer.writeUTFBytes('{}');
            writer.writeInt(Buffer.byteLength('[{"name": "broken", "params": null}]'));
            writer.writeUTFBytes('[{"name": "broken", "params": null}]');
            writer.writeInt(0);


            writer = handler.handle(writer.getBuffer());
            var reader = new ByteStreamReader(writer.getBuffer());

            removeContextFile(config, logicName);


            var errorLength = Buffer.byteLength('Holy cow!', 'utf8');

            reader.readInt().should.be.equal(errorLength + 8);
            reader.readInt().should.be.equal(3);
            reader.readInt().should.be.equal(errorLength);
            reader.readUTFBytes(errorLength).should.be.equal('Holy cow!');
        });

        it('should return a dump in success_response', function()
        {
            var logicPath = path.normalize(__dirname);
            var logicName = 'default';
            var config = getConfig(logicPath);

            createContextFile(config, logicName);

            var handler = new ApplyCommandsHandler(config);

            var writer = new ByteStreamWriter();
            writer.writeInt(Buffer.byteLength(logicName, 'utf8'));
            writer.writeUTFBytes(logicName);
            writer.writeInt(Buffer.byteLength('{}'));
            writer.writeUTFBytes('{}');
            writer.writeInt(Buffer.byteLength('[{"name": "example", "params": null}]'));
            writer.writeUTFBytes('[{"name": "example", "params": null}]');
            writer.writeInt(0);

            writer = handler.handle(writer.getBuffer());
            var reader = new ByteStreamReader(writer.getBuffer());

            removeContextFile(config, logicName);

            reader.readInt(); // skip packet length
            reader.readInt().should.be.equal(4);
            var dumpLength = reader.readInt();
            JSON.parse(reader.readUTFBytes(dumpLength)).should.be.eql({x: 10});
        });
    });
});
