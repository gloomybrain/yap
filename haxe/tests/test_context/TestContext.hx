package test_context;

import test_commands.ExternalCommand;
import test_queries.ExternalQuery;
import core.Environment;
import test_models.TestDump;
import core.BaseContext;

class TestContext extends BaseContext<TestDump>
{
    public function new(env:Environment)
    {
        super(env);
    }

    override public function init():Void
    {
        this.queries.addExternal("query", ExternalQuery);
        this.executor.addExternal("command", ExternalCommand);
    }
}
