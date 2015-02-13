/**
 * Класс среды окружения
 *
 * @param   exchangables    {Exchangables}  Доступные объекты обмена
 * @param   allowedActions  {Object}        Список разрешенных действий (хэш, в
 *                                          котором ключи - это имена действий,
 *                                          а значения по ключам имеют
 *                                          булевский тип)
 */
function Environment(exchangables, allowedActions)
{
    if (!exchangables) throw new Error("Доступные объекты обмена являются обязательным параметром!");
    if (!allowedActions) throw new Error("Список разрешенных действий является обязательным параметром!");

    /**
     * Получить текущее время в данной среде
     *
     * @return {Number} Дата в миллисекундах
     */
    this.getTime = function()
    {
        return (new Date()).getTime();
    };

    /**
     * Создать объект обмена
     *
     * @param   type            {String}  Тип создаваемого объекта обмена
     * @param   sharedParams    {Object}  Параметры создаваемого объекта
     * @param   serverParams    {Object}  Информация о получателе (либо любая
     *                                    другая служебная информация, не
     *                                    относящаяся к игровой механике)
     */
    this.createExchange = function(type, sharedParams, serverParams)
    {
        exchangables.create(type, sharedParams, serverParams);
    };

    /**
     * Использовать объект обмена
     *
     * @param type  {String}    Тип объекта обмена
     * @param id    {Number}    Идентификатор объекта обмена
     *
     * @return {Object} Данные разделяемой логики (sharedParams) объекта обмена
     */
    this.useExchange = function(type, id)
    {
        return exchangables.use(type, id);
    };

    /**
     * Вывести одно или несколько сообщений в лог
     */
    this.log = function(message)
    {
        console.log(message);
    };

    /**
     * Разрешены ли действия такого типа
     *
     * @param   type  {String}    Искомый тип
     *
     * @return        {Boolean}   true, если ращрешение есть, false иначе.
     */
    this.isActionAllowed = function(type)
    {
        return allowedActions[type];
    };

    /**
     * Подтвердить накопленные действия с объектами обмена
     *
     * @return {{used: Array, created: Array}}
     */
    this.commit = function()
    {
        return exchangables.commit();
    };

    /**
     * Откатить все неподтвержденные действия
     */
    this.rollback = function()
    {
        exchangables.rollback();
    };

}

module.exports = Environment;
