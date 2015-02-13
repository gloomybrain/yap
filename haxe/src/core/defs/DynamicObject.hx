package core.defs;

@:forward

/**
* Абстракт для упрощения работы с анонимными объектами. Позволяет обращаться к ним как к Map/IMap.
* Может рассматривать анонимные объекты как типизированные структуры.
**/
abstract DynamicObject<T>(Dynamic<T>) from Dynamic
{
    public inline function new( )
    {
        this = {};
    }

    @:arrayAccess
    public inline function set( key:String, value:T ):Void
    {
        Reflect.setField( this, key, value );
    }

    @:arrayAccess
    public inline function get( key:String ):Null<T>
    {
        return Reflect.field( this, key );
    }

    public inline function exists( key:String ):Bool
    {
        return Reflect.hasField( this, key );
    }

    public inline function remove( key:String ):Bool
    {
        return Reflect.deleteField( this, key );
    }

    public inline function keys( ):Array<String>
    {
        return Reflect.fields( this );
    }
}
