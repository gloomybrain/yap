module.exports = function(error, writer)
{
    var message = String(error);
    var messageLength = Buffer.byteLength(message, 'utf8');

    writer.writeInt(messageLength + 8); // длина содержимого пакета
    writer.writeByte(3);                 // тип error_response
    writer.writeInt(messageLength);     // длина строки с описанием ошибки
    writer.writeUTFBytes(message);      // строка с ошибкой

    return writer;
};
