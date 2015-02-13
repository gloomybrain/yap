package test_queries;

import test_models.TestDump;
import core.queries.BaseQuery;

class SimpleQuery extends BaseQuery<TestDump>
{
    override public function run(?params:Dynamic):Dynamic
    {
        return params;
    }
}
