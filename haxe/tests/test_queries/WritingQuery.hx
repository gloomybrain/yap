package test_queries;

import test_models.TestDump;
import core.queries.BaseQuery;

class WritingQuery extends BaseQuery<TestDump>
{
    override public function run(?params:Dynamic):Dynamic
    {
        // try to write - this must cause a runtime error
        model.bool = false;

        return params;
    }
}
