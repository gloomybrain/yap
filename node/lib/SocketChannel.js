/**
 * Это абстракция над unix domain socket'ом
 */

var net = require('net');

var PacketDivisor = require('./io/PacketDivisor.js');
var RawPacketHandler = require('./RawPacketHandler.js');
var ApplyCommandsHandler = require('./handlers/ApplyCommandsHandler');
var ApplyScriptHandler = require('./handlers/ApplyScriptHandler');

/**
 * @param config    {Object}    Объект конфига с полями:
 *
 * logicPath - строка с путем до шаред-логики. Путь относительно process.cwd()
 * defaultVersion - строка с именем дефолтной версии шаред-логики
 * allowedExchangables - массив строк с разрешеннами типами объектов обмена (gifts, wishes, etc.)
 * allowedActions - массив строк с разрешенными в данной песочнице действиями (читы, например)
 *
 * @param sockPath  {String}    Путь до файла с сокетом, к которому нужно подключиться
 *
 * @constructor
 */
function SocketChannel(sockPath, config)
{
    var devisor = new PacketDivisor();
    var rawHandler = new RawPacketHandler();
    rawHandler.setHandlerForType(1, new ApplyCommandsHandler(config));
    rawHandler.setHandlerForType(4, new ApplyScriptHandler());

    var socket;

    connect();

    function connect()
    {
        socket = net.connect(sockPath);   

        socket.on('connect', onConnect);
        socket.on('data', onData);
        socket.on('end', onEnd);
        socket.on('error', onError);
        socket.on('close', onClose);
    }

    function disconnect()
    {
        socket.removeAllListeners();
        socket.destroy();

        socket = null;
    }

    function reconnect()
    {
        disconnect();
        setTimeout(connect, 1000);
    }

    function onConnect ()
    {
        console.log(sockPath, ' connected to ', sockPath);
    }

    function onData (buffer)
    {
        var rawPackets = devisor.appendBytes(buffer);
        for (var i = 0; i < rawPackets.length; i++)
        {
            var packet = rawPackets[i];
            var streamWriter = rawHandler.handle(packet);
            socket.write(streamWriter.getBuffer());
        }
    }

    function onEnd ()
    {
        console.log(sockPath, ' disconnected from ', sockPath);
        reconnect();
    }

    function onError (error)
    {
        console.error(sockPath, ' got an error: ', error);
        reconnect();
    }

    function onClose (had_error)
    {
        console.log(sockPath, ' closed; error: ', had_error);
        reconnect();
    }
}

module.exports = SocketChannel;
