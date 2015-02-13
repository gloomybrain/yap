package ;

import core.models.collections.ValueMapImpl;
import core.actions.ActionLog;
import TestUtils;
import test_models.InnerObject;
import test_models.Coords;
import test_models.InnerModel;
import test_models.TestDump;
import haxe.unit.TestCase;

class ModelTest extends TestCase
{
    private var model:TestDump;
    private var dump:Dynamic;

    override public function setup():Void
    {
        dump = TestUtils.getTestDump();

        model = new TestDump();
        model.fromDump(dump);
    }

    public function testFromDumpAndToDump():Void
    {
        var modelDump:Dynamic = model.toDump();

        assertEquals(Utils.hash(modelDump), Utils.hash(dump));
    }

    @:access(core.models.ValueBase)
    public function testFromDumpHashIntegrity():Void
    {
        var hash:Float = model.__hash;
        var modelDump:Dynamic = model.toDump();

        for(i in 0...100)
        {
            model.fromDump(model.toDump());

            assertEquals(Utils.hash(modelDump), Utils.hash(model.toDump()));
            assertEquals(hash, model.__hash);
        }
    }

    @:access(core.models.ValueBase)
    @:access(core.actions.ActionLog)
    private function testStateHashIntegrity():Void
    {
        var hash:Float = model.__hash;

        model.nothing = new InnerModel();
        model.nothing = null;
        model.nothing = new InnerModel();
        model.nothing = null;

        var n:InnerModel = new InnerModel();
        n.integer = 123;
        model.nothing = n;

        model.nothing.string = "ewrwe";
        model.nothing.coords = new Coords(34.35,214.50000000001);
        model.nothing.coords = new Coords(34.35,214.40000000007);
        model.nothing.object = new InnerObject();
        model.nothing.object.y = "hi bitch";
        model.nothing.coords = null;

        model.nothing = null;


        // bare map
        model.bare_map = null;
        model.bare_map = new ValueMapImpl<String>();
        model.bare_map["a"] = "x";
        model.bare_map["b"] = "x";
        model.bare_map["c"] = "?";

        model.number *= 1.89123;
        model.number /= 1.89123;


        assertEquals(Utils.hash(TestUtils.getTestDump()), Utils.hash(model.toDump()));
        assertEquals(hash, model.__hash);

        model.fromDump(model.toDump());

        assertEquals(hash, model.__hash);
    }
}
