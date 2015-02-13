/**
 * Обработчик пакета apply_commands
 */

var Path = require('path');

var ApplyCommandsRequest = require('../packets/ApplyCommandsRequest');
var ApplyCommandsResponse = require('../packets/ApplyCommandsResponse');
var BatchRunnerFactory = require('../process/BatchRunnerFactory');

function ApplyCommandsHandler(config)
{
    if (typeof(config) !== 'object')                    throw new Error('Невалидный конфиг: переден не-object!');
    if (config === null)                                throw new Error('Невалидный конфиг: переден null!');
    if (!config.hasOwnProperty('logicPath'))            throw new Error('Невалидный конфиг: нет logicPath!');
    if (!config.hasOwnProperty('defaultVersion'))       throw new Error('Невалидный конфиг: нет defaultVersion!');
    if (!config.hasOwnProperty('allowedExchangables'))  throw new Error('Невалидный конфиг: нет allowedExchangables!');
    if (!config.hasOwnProperty('allowedActions'))       throw new Error('Невалидный конфиг: нет allowedActions!');

    var factory = new BatchRunnerFactory(
        Path.normalize(Path.join(process.cwd(), config['logicPath'])),
        config['defaultVersion'],
        config['allowedExchangables'],
        config['allowedActions']
    );

    this.handle = function(buffer)
    {
        // читаем пакет из буфера
        var request = ApplyCommandsRequest.readFromBuffer(buffer);

        if (request.error)
        {
            return (new ApplyCommandsResponse(null, null, null, request.error)).writer;
        }

        // получаем BatchRunner с нужной версией логики
        var runner = factory.getVersion(request.logicVersion);

        // прогоняем батч
        var batchResult = runner.run(request.dump, request.commands, request.unusedExchangables);

        var response = new ApplyCommandsResponse(
            batchResult.dump,
            batchResult.exchangables.created,
            batchResult.exchangables.used,
            batchResult.error
        );

        return response.writer;
    }
}

module.exports = ApplyCommandsHandler;
