package core.actions;

class Event implements IAction
{
    public var opName(default, null):String;

    private var _name:String;
    private var _params:Dynamic;

    public function new(name:String, params:Dynamic = null)
    {
        _name = name;
        _params = params;

        this.opName = ChangeOp.EVENT;
    }

    public function rollback():Void
    {
        // do nothing
    }

    public function toDump():ActionDump
    {
        return {
            path: [_name],
            newValue: _params,
            opName: this.opName
        };
    }

    #if debug
    public function toString():String
    {
        return Utils.hash(this.toDump());
    }
    #end
}
