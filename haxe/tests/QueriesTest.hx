package ;

import test_queries.WritingQuery;
import test_queries.ExternalQuery;
import test_queries.SimpleQuery;
import core.queries.Queries;
import test_models.TestDump;
import haxe.unit.TestCase;

class QueriesTest extends TestCase
{
    private var model:TestDump;
    private var dump:Dynamic;
    private var queries:Queries<TestDump>;

    override public function setup():Void
    {
        dump = TestUtils.getTestDump();

        model = new TestDump();
        model.fromDump(dump);
        queries = new Queries<TestDump>(model, null);
    }

    public function testSimple():Void
    {
        var params:Dynamic = {a: 4};

        assertEquals(params, queries.run(SimpleQuery, params));
    }

    public function testExternal():Void
    {
        var params:Dynamic = [5,2];

        queries.addExternal("fuuu", ExternalQuery);
        assertEquals( params, queries.runExternal("fuuu", params));
    }

    public function testWriteLock():Void
    {
        var error = null;

        try
        {
            queries.run(WritingQuery, {});
        }
        catch(err:Error)
        {
            error = err;
        }

        assertTrue(error != null);
        assertEquals("Unable to write value!", error.message);

        // test that write is enabled now
        model.integer--;
    }
}
