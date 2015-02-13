package core.actions;

interface IAction
{
    var opName(default, null):String;

    function rollback():Void;
    function toDump():Dynamic;

    #if debug
    function toString():String;
    #end
}
