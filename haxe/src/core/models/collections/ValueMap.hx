package core.models.collections;

@:dce
@:forward(__name, __parent, __hash, __isRooted, setRooted, exists, remove, keys, iterator, fromDump, toDump)
abstract ValueMap<T>(ValueMapBase<T>) from ValueMapBase<T> to ValueMapBase<T>
{
    public inline function new(origin:ValueMapBase<T>) { this = origin; }

    @:arrayAccess public inline function get(key:String):T { return this.get(key); }
    @:arrayAccess public inline function set(key:String, value:T):Void { this.set(key, value); }
}
