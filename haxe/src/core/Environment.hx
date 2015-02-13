package core;


#if (tests || flash)
class Environment
{
    public function new() {};
    public function getTime():Float { return 0; }
    public function createExchange(type:String, clientParams:Dynamic, serverParams:Dynamic):Void {}
    public function useExchange(type:String, id:Int):Dynamic { return null; }
    public function log(message:String):Void {}
    public function isActionAllowed(type:String):Bool { return false; }
    public function commit():Dynamic { return null; }
    public function rollback():Void {}
}
#else
extern class Environment
{
    public function new();
    public function getTime():Float;
    public function createExchange(type:String, clientParams:Dynamic, serverParams:Dynamic):Void;
    public function useExchange(type:String, id:Int):Dynamic;
    public function log(message:String):Void;
    public function isActionAllowed(type:String):Bool;
    public function commit():Dynamic;
    public function rollback():Void;
}
#end
