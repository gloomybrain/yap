package core.defs;

@:forward

/**
* Абстракт, который запрещает изменять анонимный объект - добавлять или удалять ключи.
* Методы set и remove - это заглушки, которые помешают изменить объект.
* Они нужны, чтобы было возможно оставить @:forward.
* А @:forward, в свою очередь, нужен, чтобы к элементам анонимного объекта был доступ через точку: object.key_name.bla_bla.
**/
abstract DynamicObjectRead<T>(DynamicObject<T>) from DynamicObject<T>
{
    public inline function new()
    {
        this = {};
    }

    @:arrayAccess
    public inline function get(key:String):Null<T>
    {
        return this.get(key);
    }

    public inline function set():Void {}
    public inline function remove():Void {}
}
