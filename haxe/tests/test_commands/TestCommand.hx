package test_commands;

import test_queries.SimpleQuery;
import test_models.TestDump;
import core.commands.BaseCommand;

class TestCommand extends BaseCommand<TestDump>
{
    override public function execute(?params:Dynamic):Void
    {
        var string:String = "test_string";
        var queryResult:String = this.queries.run(SimpleQuery, string);

        model.string = params;
        model.inner.string = queryResult + string + params;
    }
}
