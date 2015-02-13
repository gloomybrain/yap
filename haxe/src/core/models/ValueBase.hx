package core.models;

import core.actions.ActionLog;

class ValueBase
{
    public static inline var PRECISION:Float = 1e4;
    public static inline var DIVISOR:Float = 1e6;

    @:allow(core.actions.ChangeBase)
    private var __name:String;

    @:allow(core.actions.ChangeBase)
    private var __parent:ValueBase;

    @:allow(core.BaseContext)
    @:allow(core.actions.ChangeBase)
    private var __hash:Float;

    private var __isRooted:Bool;

    public function new()
    {
        __name = null;
        __parent = null;
        __hash = 1;
        __isRooted = false;
    }

    private function reset():Void { throw new Error('Not implemented!'); }

    public function fromDump(dump:Dynamic):Void { throw new Error('Not implemented!'); }
    public function toDump():Dynamic { throw new Error('Not implemented!'); }

    @:allow(core.BaseContext)
    private function setRooted(value:Bool):Void { throw new Error('Not implemented!'); }

    private function init() {}

    private inline function assertWriteEnabled():Void
    {
        if (!ActionLog._valueWriteEnabled) throw new Error('Unable to write value!');
    }

    private function removeParent(value:ValueBase):Void
    {
        if (value == null) return;

        value.__parent = null;
        value.__name = null;
    }

    private function updateHash(fieldOldHash:Float, fieldNewHash:Float):Void
    {
        var myOldHash = __hash;

        fieldOldHash = round(fieldOldHash);
        fieldNewHash = round(fieldNewHash);

        var myNewHash:Float = round(myOldHash - fieldOldHash + fieldNewHash);

        __hash = myNewHash;

        if (__parent != null) __parent.updateHash(myOldHash, myNewHash);
    }

    private inline function round(float:Float):Float
    {
        return Math.round(modulo(float) * PRECISION) / PRECISION;
    }

    private inline function modulo(float:Float):Float
    {
        if(float > DIVISOR || float < -DIVISOR)
            float %= DIVISOR;

        return float;
    }

    @:final
    private function getHashChain():Array<Float>
    {
        var result:Array<Float> = [];

        var target:ValueBase = this;
        while (target != null)
        {
            result.push(target.__hash);
            target = target.__parent;
        }

        return result;
    }

    inline private function hashOfBool(value:Bool):Float
    {
        return value ? 1 : 0;
    }

    inline private function hashOfInt(value:Int):Float
    {
        return value;
    }

    inline private function hashOfFloat(value:Float):Float
    {
        if (Math.isNaN(value)) return 0;
        if (!Math.isFinite(value)) return ((value > 0) ? 1 : -1);

        return value;
    }

    private function hashOfString(value:String):Float
    {
        if (value == null) return 0;

        var tmp:Int = 0;
        var len = value.length;
        while (len-- > 0)
        {
            tmp += StringTools.fastCodeAt(value, len);
        }

        return tmp;
    }

    inline private function hashOfValueBase(value:ValueBase):Float
    {
        if (value == null) return 0;

        return value.__hash;
    }
}
