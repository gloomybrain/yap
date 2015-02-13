var FS = require('fs');
var Path = require('path');
var BatchRunner = require('./BatchRunner');
var Environment = require('./Environment');
var Exchangables = require('./Exchangables');

/**
 * Фабрика объектов BatchRunner. Нужна для выдачи объектов BatchRunner с
 * указанной версией скриптинга.
 *
 * @param logicPath             {String}    Путь до папаки с файлами shared-логики
 * @param defaultVersion        {String}    Имя версии shared-логики по-умолчанию
 * @param allowedExchangables   {Array}     Массив имен разрешенных типов объектов обмена
 * @param allowedActions        {Array}     Массив имен разрешенных в данной песочнице действий
 *
 * @constructor
 */
function BatchRunnerFactory(logicPath, defaultVersion, allowedExchangables, allowedActions)
{
    if (typeof(logicPath) !== 'string' || !logicPath)
    {
        throw new Error('Не задан путь до логики');
    }

    if (typeof(defaultVersion) !== 'string' || !defaultVersion)
    {
        throw new Error('Не задана версия логики по-умолчанию!');
    }

    if (
        typeof(allowedExchangables) !== 'object' ||
        allowedExchangables == null ||
        allowedExchangables.constructor !== Array
    )
    {
        throw new Error('Не задан список доступных объектов обмена!');
    }

    if (
        typeof(allowedActions) !== 'object' ||
        allowedActions === null ||
        allowedActions.constructor !== Array
    )
    {
        throw new Error('Не задан список разрешенных действий!');
    }

    var _alive = {};
    var _dead = {};
    var _default;

    /**
     * Получить объект BatchRunner с определенной версией контекста в нем.
     * Если таковой не найден в кеше версий, он ищется в файловой системе.
     * Если его и там нет, то возвращается null. Если же так или иначе нужный
     * BatchRunner найден, то он и возвращается.
     *
     * @param version   {String}    Имя версии
     *
     * @returns {BatchRunner}
     */
    this.getVersion = function(version)
    {
        if(!version) return getDefault();

        // ищем версию в уже загруженных (живых). Если находим - то возвращаем
        if (_alive.hasOwnProperty(version))
        {
            return _alive[version];
        }

        // ищем версию в мертвых, если находим то понятное дело возвращаем дефолтную
        if (_dead.hasOwnProperty(version))
        {
            return getDefault();
        }

        // эту версию еще ни разу не запрашивали (нет ни в 'живых', ни в 'мертвых')
        // пытаемся отыскать версию в файловой системе
        var runner = loadRunnerVersion(version);
        if(runner)
        {
            _alive[version] = runner;

            return runner;
        }
        else
        {
            _dead[version] = true;

            return getDefault();
        }
    };

    /**
     * Возвращает версию по умолчанию (ту, на которую указывает current.version).
     *
     * @returns    {BatchRunner}
     */
    var getDefault = function()
    {
        if(!_default)
        {
            var runner = loadRunnerVersion(defaultVersion);

            if(!runner)
                throw new Error('Не найдена версия скриптинга по-умолчанию!');

            _default = runner;
        }

        return _default;
    };

    var loadRunnerVersion = function(version)
    {
        var modulePath = Path.join(logicPath, version + '.js');

        console.log("loading version from " + modulePath);
        if (!FS.existsSync(modulePath))
        {
            return null;
        }

        var ContextClass = require(modulePath).Context;

        var exchangables = new Exchangables(allowedExchangables);
        var environment = new Environment(exchangables, allowedActions);
        var context = new ContextClass(environment);

        return new BatchRunner(context, exchangables);
    };
}

module.exports = BatchRunnerFactory;
