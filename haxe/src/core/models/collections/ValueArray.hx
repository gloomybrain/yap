package core.models.collections;

@:dce
@:forward(__name, __parent, __hash, __isRooted, setRooted, length, iterator, push, pop, shift, unshift, insert, remove, fromDump, toDump)
abstract ValueArray<T>(ValueArrayBase<T>) from ValueArrayBase<T> to ValueArrayBase<T>
{
    public inline function new(origin:ValueArrayBase<T>) { this = origin; }

    @:arrayAccess public inline function get(index:Int):T { return this.get(index); }
    @:arrayAccess public inline function set(index:Int, value:T):Void { this.set(index, value); }
}
