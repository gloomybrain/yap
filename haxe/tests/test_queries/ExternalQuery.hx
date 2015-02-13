package test_queries;

import test_models.TestDump;
import core.queries.BaseQuery;

class ExternalQuery extends BaseQuery<TestDump>
{
    override public function run(?params:Dynamic):Dynamic
    {
        return this.queries.run(SimpleQuery, params);
    }
}
