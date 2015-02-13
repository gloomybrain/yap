package core.models.collections;

class ValueArrayBase<T> extends ValueBase
{
    public var length(get, never):Int;

    private var _data:Array<T>;

    public function new(data:Array<T> = null)
    {
        super();

        if (data == null)
        {
            _data = new Array<T>();
        }
        else
        {
            _data = data.copy();
        }
    }

    @:final
    override private function reset():Void
    {
        __hash = 1;
        _data = new Array<T>();
    }

    private function addParent(value:ValueBase, index:Int, allowReparent:Bool = false):Void
    {
        if (value == null) return;

        if(value.__parent != null && !allowReparent) throw new Error("Unable to re-parent value!");

        value.__parent = this;
        #if (js || flash)
        value.__name = untyped String(index);
        #else
        value.__name = Std.string(index);
        #end
    }

    private inline function reparentAll()
    {
        var index = 0;
        for (v in _data)
        {
            addParent(cast v, index, true);
            index++;
        }
    }

    public function get(index:Int):T
    {
        return _data[index];
    }

    public function set(index, value:T):Void { throw new Error('Not implemented!'); }

    public function iterator():Iterator<T>
    {
        return _data.iterator();
    }

    public function get_length():Int
    {
        return _data.length;
    }

    public function push(value:T):Int { throw new Error('Not implemented!'); }

    public function pop():T { throw new Error('Not implemented!'); }

    public function shift():T { throw new Error('Not implemented!'); }

    public function unshift(value:T):Void { throw new Error('Not implemented!'); }

    public function insert(value:T, index:Int):Void { throw new Error('Not implemented!'); }

    public function remove(index:Int):T { throw new Error('Not implemented!'); }

    override public function fromDump(dump:Dynamic):Void { throw new Error('Not implemented!'); }

    override public function toDump():Dynamic { throw new Error('Not implemented!'); }
}
