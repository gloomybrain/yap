/**
 * Обработчик пакета apply_script
 */

var ByteStreamWriter = require('../io/ByteStreamWriter.js');

function ApplyScriptHandler()
{
    this.handle = function(buffer)
    {
        var writer = new ByteStreamWriter();

        var stringLength = Buffer.byteLength('handleScript', 'utf8');
        var packetLength = 4 + // type
                            4 + // string length
                            stringLength;

        writer.writeInt(packetLength);
        writer.writeByte(5); // apply_script_success_response
        writer.writeInt(stringLength);
        writer.writeUTFBytes('handleScript');

        return writer;
    }
}

module.exports = ApplyScriptHandler;
