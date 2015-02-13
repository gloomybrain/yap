package core.models.collections;

class ValueMapBase<T> extends ValueBase
{
    private var _data:Map<String, T>;

    public function new(data:Map<String, T> = null)
    {
        super();

        _data = new Map<String, T>();

        if (data != null)
        {
            for (key in data.keys())
            {
                _data[key] = data[key];
            }
        }
    }

    @:final
    override private function reset():Void
    {
        __hash = 1;
        _data = new Map<String, T>();
    }

    private function addParent(value:ValueBase, key:String):Void
    {
        if (value == null) return;

        if(value.__parent != null) throw new Error("Unable to re-parent value!");

        value.__parent = this;
        value.__name = key;
    }

    private function insert(key:String, value:T):Void { throw new Error('Not implemented!'); }

    public function exists(key:String):Bool
    {
        return _data.exists(key);
    }

    public function get(key:String):T
    {
        return _data[key];
    }

    public function set(key:String, value:T):Void { throw new Error('Not implemented!'); }

    public function remove(key:String):Void { throw new Error('Not implemented!'); }

    public function keys():Iterator<String>
    {
        var it = _data.keys();
        var sortedKeys:Array<String> = [];

        while (it.hasNext()) sortedKeys.push(it.next());

        return Utils.sortStringArray(sortedKeys).iterator();
    }

    public function iterator():Iterator<T>
    {
        var sortedValues:Array<T> = [];
        var it = this.keys();

        while (it.hasNext()) sortedValues.push(_data[it.next()]);

        return sortedValues.iterator();
    }

    override public function fromDump(dump:Dynamic):Void { throw new Error('Not implemented!'); }

    override public function toDump():Dynamic { throw new Error('Not implemented!'); }
}
