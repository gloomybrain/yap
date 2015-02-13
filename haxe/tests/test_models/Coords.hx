package test_models;

import core.models.Value;

class Coords extends Value
{
    public var x:Float;
    public var y:Float;

    public function new(?x:Float = 0, ?y:Float = 0)
    {
        super();

        this.x = x;
        this.y = y;
    }
}
