package ;

import test_commands.ExternalCommand;
import test_commands.TestCommand;
import core.commands.Executor;
import core.queries.Queries;
import test_models.TestDump;
import haxe.unit.TestCase;

class CommandsTest extends TestCase
{
    private var model:TestDump;
    private var dump:Dynamic;
    private var queries:Queries<TestDump>;
    private var executor:Executor<TestDump>;

    override public function setup():Void
    {
        dump = TestUtils.getTestDump();

        model = new TestDump();
        model.fromDump(dump);
        queries = new Queries<TestDump>(model, null);
        executor = new Executor<TestDump>(model, queries, null);
    }

    public function testSimple():Void
    {
        executor.execute(TestCommand, "ololo");

        assertEquals("ololo", model.string);
    }

    public function testExternal():Void
    {
        executor.addExternal("oops", ExternalCommand);
        executor.executeExternal("oops", { arg: "ololosh" });

        assertEquals("ololosh", model.string);
    }
}
