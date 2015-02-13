package core.actions;

@:allow(core.models.ValueBase)
@:allow(core.BaseContext)
@:allow(core.queries.Queries)
class ActionLog
{
    private static var _loggingEnabled:Bool = true;
    private static var _valueWriteEnabled:Bool = true;
    private static var _actions:Array<IAction> = [];

    public static function rollback()
    {
        ActionLog._loggingEnabled = false;

        var len = _actions.length;
        while (len-- > 0)
        {
            _actions[len].rollback();
        }

        ActionLog._loggingEnabled = true;
    }

    inline public static function sendEvent(name:String, params:Dynamic):Void
    {
        _actions.push(new Event(name, params));
    }

    private static function commit():Array<ActionDump>
    {
        var result:Array<ActionDump> = [];

        for (action in _actions)
        {
            result.push(action.toDump());
        }

        _actions = [];

        return result;
    }

    #if tests
    public static function _commit():Array<ActionDump>
    {
        return commit();
    }
    #end

    #if debug
    private static function calculateChangeHash():String
    {
        var result = '';

        for (action in _actions)
        {
            result += '${action.toString()}';
        }

        return result;
    }
    #end
}
