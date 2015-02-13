/**
 * Обработчик входящих пакетов из unix domain socket.
 * Единственное что делает этот класс - это принимает пакет, определяет
 * его тип и отдает этот пакет в обработчик пакетов такого типа.
 *
 * @constructor
 */
function RawPacketHandler()
{
    var _handlers = [];

    /**
     * Зарегисрировать обработчик пакетов для данного типа
     *
     * @param handler   Обработчки пакетов этого типа
     * @param type      Тип пакета
     */
    this.setHandlerForType = function(type, handler)
    {
        if (!handler || !handler.hasOwnProperty('handle') || typeof(handler.handle) !== 'function')
        {
            throw new Error('handler must have a \'handle\' method!');
        }

        if (isNaN(type) || type !== ~~type)
        {
            throw new Error('type must be an integer!');
        }

        _handlers[type] = handler;
    };

    /**
     * Обработать пакет из unix domain socket
     *
     * @param rawPacket {RawPacket} пакет из unix domain socket
     *
     * @returns {ByteStramWriter}
     */
	this.handle = function(rawPacket)
	{
        var handler = _handlers[rawPacket.type];

        if (!handler)
        {
            throw new Error('Unable to handle packet with type: ' + rawPacket.type);
        }

        return handler.handle(rawPacket.data);
	};
}

module.exports = RawPacketHandler;
