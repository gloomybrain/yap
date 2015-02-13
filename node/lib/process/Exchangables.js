/**
 * Объект для работы с exchangables, умеющий хранить, создавать и списывать
 * exchangables. Вынесен отдельно из Environment в целях упрощения API
 *
 * @param allowed {Array}   массив строк, содержащий имена разрешенных типов
 *                          exchangables
 *
 * @constructor
 */
function Exchangables(allowed)
{
    var _allowed = {};
    var _unused = {};
    var _used = [];
    var _created = [];

    if(arguments.length)
    {
        if (typeof(allowed) !== 'object' || allowed == null || allowed.constructor != Array)
        {
            throw new Error('allowed must be an Array!');
        }

        var len = allowed.length;
        while(len--)
            _allowed[allowed[len]] = true;
    }

    /**
     * Обновить список неиспользованных объектов обмена
     *
     * @param unused    {Array}    Массив, содержащий неиспользованные объекты обмена
     */
    this.update = function(unused)
    {
        if (typeof(unused) !== 'object' || unused == null || unused.constructor !== Array)
        {
            throw new Error('unused must be an Array!');
        }

        _unused = {};

        for (var i = 0; i < unused.length; i++)
        {
            var exchangable = unused[i];

            if (!_unused.hasOwnProperty(exchangable.type))
            {
                _unused[exchangable.type] = {};
            }

            _unused[exchangable.type][exchangable.id] = exchangable.sharedParams;
        }

        _used = [];
        _created = [];
    };

    /**
     * Создать новый объект обмена
     *
     * @param type          {String}    Тип объекта обмена
     * @param sharedParams  {Object}    Параметры доступные разделяемой логике
     * @param serverParams  {Object}    Параметры доступные серверу
     */
    this.create = function(type, sharedParams, serverParams)
    {
        if(!_allowed.hasOwnProperty(type))
        {
            throw new Error('Not allowed to create exchangables of type: ' + type);
        }

        var exchange = {
            type: type,
            sharedParams: sharedParams,
            serverParams: serverParams
        };

        _created.push(exchange);
    };

    /**
     * Использовать доступный объект обмена. Важно: нельзя использовать объект
     * обмена, созданный самим пользователем.
     *
     * @param type  {String}    Тип объекта обмена
     * @param id    {Number}    Идентификатор объекта обмена
     */
    this.use = function(type, id)
    {
        if (typeof(type) !== 'string' || type === '')
            throw new Error('Excangable type must be non-empty String!');

        if (typeof(id) !== 'number' || isNaN(id))
            throw new Error('Exchangable id must be a Number');

        if(!_allowed.hasOwnProperty(type))
            throw new Error('Not allowed to use exchangables of type: ' + type);

        if (!_unused.hasOwnProperty(type))
            throw new Error('All exchangables of type ' + type + ' were already used!');

        if (!_unused[type].hasOwnProperty(id.toString()))
            throw new Error('Exchangable with id ' + id + ' does not exist!');

        var exchange = {
            type: type,
            id: id,
            sharedParams: _unused[type][id]
        };

        _used.push(exchange);
        delete _unused[type][id];

        for (var exchangable_id in _unused[type])
        {
            return;
        }

        delete _unused[type];
    };

    /**
     * Подтвердить все накопленные операции с объектами обмена
     *
     * @returns {{used: Array, created: Array}}
     */
    this.commit = function()
    {
        for (var i = 0; i < _used.length; i++)
        {
            delete _used[i].sharedParams;
        }

        var result = {
            used: _used,
            created: _created
        };

        _used = [];
        _created = [];

        return result;
    };

    /**
     * Откатить все накопленные операции с объектами обмена
     */
    this.rollback = function()
    {
        while(_used.length)
        {
            var exchangable = _used.pop();

            if (!_unused.hasOwnProperty(exchangable.type)) _unused[exchangable.type] = {};

            _unused[exchangable.type][exchangable.id] = exchangable.sharedParams;
        }

        _created = [];
    };
    
}

module.exports = Exchangables;
