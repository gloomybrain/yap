package test_commands;

import core.commands.BaseCommand;
import test_models.TestDump;

class ExternalCommand extends BaseCommand<TestDump>
{
    override public function execute(?params:Dynamic):Void
    {
        executor.execute(TestCommand, params.arg);
    }
}
