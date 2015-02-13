var ByteStreamWriter = require('../io/ByteStreamWriter');
var writeErrorResponse = require('./writeErrorResponse');

var ApplyCommandsResponse = function(dump, created, used, error)
{
    var writer = new ByteStreamWriter();

    if (error)
    {
        this.writer = writeErrorResponse(String(error), writer);
        return;
    }

    var resultDumpString = JSON.stringify(dump);
    var resultDumpStringLength = Buffer.byteLength(resultDumpString, 'utf8');

    var packetLength =  1 + // type
        4 + // dump length
        resultDumpStringLength + // dump
        4 + // num created
        4; // num used

    var i;
    var createdSerialized = [];

    for (i = 0; i < created.length; i++)
    {
        var o = {};

        o.type = created[i].type;
        packetLength += 4; // type name length
        packetLength += Buffer.byteLength(o.type, 'utf8');

        o.sharedParams = JSON.stringify(created[i].sharedParams);
        packetLength += 4; // sharedParams length
        packetLength += Buffer.byteLength(o.sharedParams, 'utf8');

        o.serverParams = JSON.stringify(created[i].serverParams);
        packetLength += 4; // serverParams length
        packetLength += Buffer.byteLength(o.serverParams, 'utf8');

        createdSerialized[i] = o;
    }

    for (i = 0; i < used.length; i++)
    {
        packetLength += 4; // type name length
        packetLength += Buffer.byteLength(used[i].type, 'utf8');
        packetLength += 4; // used[i].id
    }


    // длина пакета
    writer.writeInt(packetLength);

    // success_response
    writer.writeByte(2);

    // длина json-строки с измененным состоянием пользователя
    writer.writeInt(resultDumpStringLength);

    // json-строка с измененным состоянием пользователя
    writer.writeUTFBytes(resultDumpString);

    //  количество использованных объектов обмена
    writer.writeInt(used.length);

    for (i = 0; i < used.length; i++)
    {
        // длина названия типа объекта обмена
        writer.writeInt(Buffer.byteLength(used[i].type, 'utf8'));

        // название типа объекта обмена
        writer.writeUTFBytes(used[i].type);

        // числовой идентификатор объекта обмена
        writer.writeInt(used[i].id);
    }

    // количество созданных объектов обмена
    writer.writeInt(createdSerialized.length);

    for (i = 0; i < createdSerialized.length; i++)
    {
        // длина названия типа объекта обмена
        writer.writeInt(Buffer.byteLength(createdSerialized[i].type, 'utf8'));

        // название типа объекта обмена
        writer.writeUTFBytes(createdSerialized[i].type);

        // длина json-строки с описанием sharedParams объекта обмена
        writer.writeInt(Buffer.byteLength(createdSerialized[i].sharedParams, 'utf8'));

        // json-строка с описанием sharedParams объекта обмена
        writer.writeUTFBytes(createdSerialized[i].sharedParams);

        // длина json-строки с описанием serverParams объекта обмена
        writer.writeInt(Buffer.byteLength(createdSerialized[i].serverParams, 'utf8'));

        // json-строка с описанием serverParams объекта обмена
        writer.writeUTFBytes(createdSerialized[i].serverParams);
    }

    this.writer = writer;
};

module.exports = ApplyCommandsResponse;