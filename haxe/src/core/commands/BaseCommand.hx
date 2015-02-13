package core.commands;

import core.queries.Queries;

@:allow(core.commands.Executor)
class BaseCommand<T>
{
    private var model:T;
    private var queries:Queries<T>;
    private var executor:Executor<T>;
    private var environment:Environment;

    @:final
    @:private
    private function new(model:T, queries:Queries<T>, executor:Executor<T>, environment:Environment)
    {
        this.model = model;
        this.queries = queries;
        this.executor = executor;
        this.environment = environment;
    }

    private function execute(?params:Dynamic):Void
    {
        throw new Error("Must override in implementation!");
    }
}
