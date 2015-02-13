package ;

#if (js || flash)

extern class Error
{
    public function new(message:String);
    public var message(default, never):String;
}

#elseif cs

@:native("System.Exception")
extern class ErrorData
{
    public function new(message:String);
    public var Message(default, never):String;
}

abstract Error(ErrorData)
{
    public inline function new(message:String) this = new ErrorData(message)
    public var message(get, never):String;
    private inline function get_message():String return this.Message;
}

#else

abstract Error(String)
{
    public inline function new(message:String) this = message;
    public var message(get, never):String;
    private inline function get_message():String return this;
}

#end
