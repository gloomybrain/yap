package data;

import core.models.collections.ValueMap;
import core.models.Value;
import core.models.collections.ValueArray;

class Dump extends Value
{
    public var integer:Int;
    public var number:Float;
    public var string:String;
    public var bool:Bool;

    public var bare_array:ValueArray<Int>;
    public var complex_array:ValueArray<Coords>;

    public var bare_map:ValueMap<String>;
    public var complex_map:ValueMap<XObject>;

    public var coords:Coords;
    public var inner:InnerModel;

    public var nothing:InnerModel;
}
