package core.actions;

import core.models.ValueBase;

class ChangeBase<C:ValueBase, T, K> implements IAction
{
    public var opName(default, null):String;

    private var _model:C;
    private var _oldValue:T;
    private var _newValue:T;
    private var _key:K;
    private var _path:Array<String>;

    public function new(model:C, key:K, oldValue:T, newValue:T, opName:String = ChangeOp.VAR)
    {
        this.opName = opName;

        _model = model;
        _oldValue = oldValue;
        _newValue = newValue;
        _key = key;
        _path = this.getPath();
    }

    private function getPath():Array<String>
    {
        var target:ValueBase = cast _model;
        var path:Array<String> = [];

        // у всех моделей, кроме корневой, всегда есть name и parent (у нее нет ни того, ни другого)
        // цикл завершится как раз на корневой модели, поэтому проверка на target != null не нужна
        while(target.__parent != null)
        {
            path.unshift(target.__name);
            target = target.__parent;
        }


        #if (js || flash)
        path.push(untyped String(_key));
        #else
        path.push(Std.string(_key));
        #end

        return path;
    }

    public function rollback():Void { throw new Error('Not implemented!'); }

    public function toDump():ActionDump { throw new Error('Not implemented!'); }


    #if debug
    public function toString():String
    {
        return Utils.hash(this.toDump());
    }
    #end
}
