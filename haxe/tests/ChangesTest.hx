package ;

import test_models.XObject;
import test_models.InnerModel;
import test_models.Coords;
import test_models.InnerObject;
import haxe.Json;
import haxe.PosInfos;
import core.actions.ActionLog;
import core.actions.ActionDump;
import test_models.TestDump;
import haxe.unit.TestCase;

class ChangesTest extends TestCase
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


    public function testSimpleChanges():Void
    {
        model.integer = 81;
        model.number = 0.1;
        model.string = "Omg!";
        model.bool = false;

        model.inner.integer = 10;
        model.inner.string = "bla-bla";

        var etalonChanges:Array<ActionDump> = [
            { path: ["integer"],         newValue: 81,        opName: "var" },
            { path: ["number"],          newValue: 0.1,       opName: "var" },
            { path: ["string"],          newValue: "Omg!",    opName: "var" },
            { path: ["bool"],            newValue: false,     opName: "var" },
            { path: ["inner","integer"], newValue: 10,        opName: "var" },
            { path: ["inner","string"],  newValue: "bla-bla", opName: "var" }
        ];

        assertChangesEqual(etalonChanges, ActionLog._commit());
    }

    public function testSimpleArrayChanges():Void
    {
        model.bare_array.shift();
        model.bare_array.pop();
        model.bare_array.push(2);
        model.bare_array.unshift(12);
        model.bare_array.insert(4, 1);
        model.bare_array[1] -= 16;
        model.bare_array.remove(3);

        model.inner.object.z[1] *= 6;
        model.inner.object.z.push(8);
        model.inner.object.z.unshift(14);
        model.inner.object.z.insert(19, 0);
        model.inner.object.z.remove(1);
        model.inner.object.z.pop();
        model.inner.object.z.shift();


        var etalonChanges:Array<ActionDump> = [
            { path: ["bare_array","0"], newValue: 0,   opName: "shift"   },
            { path: ["bare_array","1"], newValue: 0,   opName: "pop"     },
            { path: ["bare_array","1"], newValue: 2,   opName: "push"    },
            { path: ["bare_array","0"], newValue: 12,  opName: "unshift" },
            { path: ["bare_array","1"], newValue: 4,   opName: "insert"  },
            { path: ["bare_array","1"], newValue: -12, opName: "index"   },
            { path: ["bare_array","3"], newValue: 0,   opName: "remove"  },

            { path: ["inner","object", "z", "1"], newValue: 12, opName: "index"   },
            { path: ["inner","object", "z", "3"], newValue: 8,  opName: "push"    },
            { path: ["inner","object", "z", "0"], newValue: 14, opName: "unshift" },
            { path: ["inner","object", "z", "0"], newValue: 19, opName: "insert"  },
            { path: ["inner","object", "z", "1"], newValue: 0,  opName: "remove"  },
            { path: ["inner","object", "z", "4"], newValue: 0,  opName: "pop"     },
            { path: ["inner","object", "z", "0"], newValue: 0,  opName: "shift"   }
        ];

        assertChangesEqual(etalonChanges, ActionLog._commit());
    }

    public function testSimpleMap():Void
    {
        model.bare_map["d"] = "ololosh";
        model.bare_map["c"] = "ololosh";
        model.bare_map["a"] = null;
        model.bare_map.remove("b");

        var etalonChanges:Array<ActionDump> = [
            { path: ["bare_map", "d"], newValue: "ololosh", opName: "insert" },
            { path: ["bare_map", "c"], newValue: "ololosh", opName: "index" },
            { path: ["bare_map", "a"], newValue: null, opName: "index" },
            { path: ["bare_map", "b"], newValue: null, opName: "remove" }
        ];

        assertChangesEqual(etalonChanges, ActionLog._commit());
    }

    public function testComplexValues():Void
    {
        model.coords = null;
        model.coords = new Coords(1,3);

        model.inner.coords = new Coords();
        model.inner = null;

        var newInnerModel:InnerModel = new InnerModel();
        newInnerModel.coords = new Coords(-1,-1);
        newInnerModel.object = new InnerObject();
        newInnerModel.object.x = "3";

        model.inner = newInnerModel;

        var etalonChanges:Array<ActionDump> = [
            { path: ["coords"], newValue: null, opName: "var" },
            { path: ["coords"], newValue: { x: 1, y: 3 }, opName: "var" },
            { path: ["inner","coords"], newValue: { x: 0, y: 0 }, opName: "var" },
            { path: ["inner"], newValue: null, opName: "var" },
            { path: ["inner"], newValue: { integer: 0, string: null, object: { x: "3", y: null, z: null }, coords: { x: -1, y: -1 }}, opName: "var" }
        ];

        assertChangesEqual(etalonChanges, ActionLog._commit());
    }

    public function testComplexArray():Void
    {
        model.complex_array[2] = new Coords(.3, .4);
        model.complex_array.shift();
        model.complex_array.pop();
        model.complex_array.push(null);
        model.complex_array.push(new Coords());
        model.complex_array.unshift(new Coords(3,8));
        model.complex_array.insert(null, 1);
        model.complex_array.remove(2);

        var etalonChanges:Array<ActionDump> = [
            { path: ["complex_array","2"], newValue: { x: .3, y: .4 }, opName: "index"   },
            { path: ["complex_array","0"], newValue: null,             opName: "shift"   },
            { path: ["complex_array","1"], newValue: null,             opName: "pop"     },
            { path: ["complex_array","1"], newValue: null,             opName: "push"    },
            { path: ["complex_array","2"], newValue: { x: 0, y: 0 },   opName: "push"    },
            { path: ["complex_array","0"], newValue: { x: 3, y: 8 },   opName: "unshift" },
            { path: ["complex_array","1"], newValue: null,             opName: "insert"  },
            { path: ["complex_array","2"], newValue: null,             opName: "remove"  }
        ];

        assertChangesEqual(etalonChanges, ActionLog._commit());
    }

    public function testComplexMap():Void
    {
        var obj:XObject = new XObject();
        obj.x = true;

        model.complex_map["nothing"] = new XObject();
        model.complex_map["uno"] = null;
        model.complex_map.remove("due");
        model.complex_map["tre"] = obj;

        var etalonChanges:Array<ActionDump> = [
            { path: ["complex_map", "nothing"], newValue: { x: false }, opName: "index" },
            { path: ["complex_map", "uno"],     newValue: null,         opName: "index" },
            { path: ["complex_map", "due"],     newValue: null,         opName: "remove" },
            { path: ["complex_map", "tre"],     newValue: { x: true },  opName: "insert" }
        ];

        assertChangesEqual(etalonChanges, ActionLog._commit());
    }

    private function assertChangesEqual(etalonChanges:Array<ActionDump>, changes:Array<ActionDump>):Void
    {
        assertEquals(etalonChanges.length, changes.length);

        var len:Int = etalonChanges.length;
        for(i in 0...len)
        {
            assertEquals(etalonChanges[i].path.join("."), changes[i].path.join("."));
            assertEquals(etalonChanges[i].opName, changes[i].opName);
            assertEquals(etalonChanges[i].newValue, changes[i].newValue);
        }
    }

    override function assertEquals<T>(etalon:T, checked:T, ?c:PosInfos):Void
    {
        super.assertEquals(Utils.hash(etalon), Utils.hash(checked));
    }

    private function stringifyChanges(changes:Array<ActionDump>):String
    {
        var changesStrs:Array<String> = [];
        for(change in changes) changesStrs.push("    { path: [\"" + change.path.join("\",\"") + "\"], newValue: " + Utils.hash(change.newValue) + ", opName: \"" + change.opName + "\" }");
        return "[\n" + changesStrs.join(",\n") + "\n]";
    }
}
