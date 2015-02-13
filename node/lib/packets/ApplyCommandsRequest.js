var ByteStreamReader = require('../io/ByteStreamReader');

/**
 *
 */
var ApplyCommandsRequest = function(logicVersion, dump, commands, unusedExchangables, error)
{
    this.logicVersion = logicVersion;
    this.dump = dump;
    this.commands = commands;
    this.unusedExchangables = unusedExchangables;
    this.error = error;
};

ApplyCommandsRequest.readFromBuffer = function(buffer)
{
    var logicVersion = null;
    var dump = null;
    var commands = null;
    var unusedExchangables = null;
    var error = null;

    var reader = new ByteStreamReader(buffer);

    try
    {
        // количество байтов в строке с названием версии логики
        var logicVersionLength = reader.readInt();

        // строка с именем версии логики
        logicVersion = reader.readUTFBytes(logicVersionLength);

        // количество байтов в строке с json-объектом дампа
        var dumpStringLength = reader.readInt();

        // строка с json-объектом дампа
        dump = JSON.parse(reader.readUTFBytes(dumpStringLength));

        // количество байтов в строке с json-массивом команд
        var commandsArrayStringLength = reader.readInt();

        // строка с json-массивом команд
        commands = JSON.parse(reader.readUTFBytes(commandsArrayStringLength));

        // количество элементов в последовательности объектов обмена (exchangable)
        var numUnusedExchangables = reader.readInt();

        unusedExchangables = [];
        while(numUnusedExchangables--)
        {
            // длина названия типа exchangable (gift, payment, wish и т.п.)
            var exchangableTypeLength = reader.readInt();

            // название типа exchangable
            var exchangableType = reader.readUTFBytes(exchangableTypeLength);

            // числовой идентификатор exchangable
            var exchangableID = reader.readInt();

            // длина json-строки с клиентскими параметрами exchangable
            var sharedParamsStringLength = reader.readInt();

            // json-строка с клиентскими параметрами exchangable
            var sharedParams = JSON.parse(reader.readUTFBytes(sharedParamsStringLength));

            // длина json-строки с серверными параметрами exchangable
            var serverParamsStringLength = reader.readInt();

            // json-строка с серверными параметрами exchangable
            var serverParams = JSON.parse(reader.readUTFBytes(serverParamsStringLength));

            unusedExchangables.push({
                type: exchangableType,
                id:exchangableID,
                sharedParams: sharedParams,
                serverParams: serverParams
            });
        }
    }
    catch (e)
    {
        error = e;
    }

    return new ApplyCommandsRequest(logicVersion, dump, commands, unusedExchangables, error);
};

module.exports = ApplyCommandsRequest;