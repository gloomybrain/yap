package core.queries;


@:allow(core.queries.Queries)

/**
* Базовый класс для любого Query.
* Как видно, запрос может быть создан только в обработчике запросов - core.queries.Queries.
**/
class BaseQuery<T>
{
    private var environment:Environment;
    private var model:T;
    private var queries:Queries<T>;

    @:final
    private function new(model:T, queriesRunner:Queries<T>, environment:Environment)
    {
        this.model = model;
        this.queries = queriesRunner;
        this.environment = environment;
    }

    public function run(?params:Dynamic):Dynamic
    {
        throw new Error("Should be overriden in implementation!");
    }
}
