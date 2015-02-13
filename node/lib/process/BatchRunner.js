/**
 * Обработчик массива команд
 *
 * @constructor
 */
function BatchRunner(context, exchangables)
{
    if (!context) throw new Error('Параметр не должен быть нулевым!');
    if (!exchangables) throw new Error('Параметр не должен быть нулевым!');

    /**
     * Исполнить все команды, присланные клиентом
     *
     * @param dump                  {Object}    Хэш, содержащий текущее состояние мира (дамп)
     * @param commands              {Array}     Массив команд, которые необходимо исполнить
     * @param unusedExchangables    {Object}    Хэш, содержащий данные о сервисах которые можно использовать
     */
    this.run = function(dump, commands, unusedExchangables)
    {
        exchangables.update(unusedExchangables);
        context.fromDump(dump);

        var batchResult = new BatchResult();

        var i;
        var len = commands.length;
        var command;
        var commandResult;

        for (i = 0; i < len; i++)
        {
            command = commands[i];
            
            str = "executing command: " + command.name + "(" + JSON.stringify(command.params || {}) + ") = " + command.hash;
            commandResult = context.execute(command.name, command.params, command.hash);

            
            if(commandResult.error)
            {
                str = "!!FAILED " + str + ": " + commandResult.error;
                batchResult.error = commandResult.error;
                
                console.log(str);
                break;
            }
            else
            {
                str = "SUCCEDED " + str;
                console.log(str);
            }

            batchResult.addActions(commandResult.actions);
            batchResult.addExchangables(commandResult.exchangables);
        }

        batchResult.dump = context.toDump();

        return batchResult;

    };
}

/**
 * Результат, возвращаемый по окончании обработки батча
 *
 * @constructor
 */
function BatchResult()
{
    this.dump = null;
    this.actions = [];
    this.stateDiff = {};
    this.exchangables = {
        used: [],
        created: []
    };
    this.error = null;

    this.addActions = function(allActions)
    {
        this.actions = this.actions.concat(allActions);
    };

    this.addExchangables = function(exchangables)
    {
        if(exchangables.created.length > 0)
        {
            this.exchangables.created = this.exchangables.created.concat(exchangables.created);
        }

        if(exchangables.used.length > 0)
        {
            this.exchangables.used = this.exchangables.used.concat(exchangables.used);
        }
    };
}

module.exports = BatchRunner;
