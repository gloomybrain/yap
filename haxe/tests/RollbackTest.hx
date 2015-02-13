package ;

import core.models.ValueBase;
import test_models.Coords;
import test_models.InnerModel;
import core.actions.ActionLog;
import TestUtils;
import test_models.TestDump;
import haxe.unit.TestCase;

class RollbackTest extends TestCase
{
    private var dump:Dynamic;
    private var model:TestDump;

    @:access(core.models.ValueBase)
    override public function setup():Void
    {
        dump = TestUtils.getTestDump();

        model = new TestDump();
        model.fromDump(dump);
        model.setRooted(true);
    }


    public function testRollback():Void
    {
        // change simple values
        model.integer = 81;
        model.number = 0.1;
        model.string = "Omg!";
        model.string = null;
        model.bool = false;
        model.inner.integer = 10;
        model.inner.integer *= 61;
        model.inner.string = "bla-bla";


        // replace whole models
        model.nothing = new InnerModel();
        model.coords = null;


        // change maps
        model.bare_map["d"] = "ololosh";
        model.bare_map["c"] = "ololosh";
        model.bare_map["a"] = null;
        model.bare_map.remove("b");


        // change arrays
        model.bare_array.shift();
        model.bare_array.pop();
        model.bare_array.push(2);
        model.bare_array.unshift(12);
        model.bare_array.insert(4, 1);
        model.bare_array[1] -= 16;
        model.bare_array.remove(3);
        model.complex_array.pop();
        model.complex_array[2] = new Coords(.3, .4);
        model.complex_array.shift();
        model.complex_array.push(null);
        model.complex_array.push(new Coords());
        model.complex_array.unshift(new Coords(3,8));
        model.complex_array.insert(null, 1);
        model.complex_array.remove(2);
        model.inner.object.z[1] *= 6;
        model.inner.object.z.push(8);
        model.inner.object.z.unshift(14);
        model.inner.object.z.insert(19, 0);
        model.inner.object.z.remove(1);
        model.inner.object.z.pop();
        model.inner.object.z.shift();

        model.complex_array = null;
        model.complex_map = null;


        ActionLog.rollback();

        assertEquals(Utils.hash(TestUtils.getTestDump()), Utils.hash(model.toDump()));
    }


    @:access(core.models.ValueBase)
    @:access(core.actions.ActionLog)
    public function testHashModuloOperation():Void
    {
        // clear changes
        ActionLog.commit();

        // modulo op will happen if hash is more than int.MAX_VALUE
        var divisor:Float = ValueBase.DIVISOR;
        var hash:Float = model.__hash;


        model.number += 1e6;//Math.pow(2,32);
        ActionLog.rollback();
        assertEquals(hash, model.__hash);


        model.inner.integer -= cast ~~(divisor * 200);
        ActionLog.rollback();
        assertEquals(hash, model.__hash);


        model.inner.integer -= cast Math.pow(2, 200);
        ActionLog.rollback();
        assertEquals(hash, model.__hash);


        model.number *= Math.pow(2,100);
        ActionLog.rollback();
        assertEquals(hash, model.__hash);
    }
}
