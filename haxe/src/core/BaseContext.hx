package core;

import core.actions.ActionDump;
import core.actions.ActionLog;
import core.models.ValueBase;
import core.commands.Executor;
import core.queries.Queries;

@:generic
class BaseContext<T:(ValueBase, {function new():Void;})>
{
    private var model:T;
    private var queries:Queries<T>;
    private var executor:Executor<T>;
    private var env:Environment;

    @:final
    public function new(environment:Environment)
    {
        model = new T();
        model.setRooted(true);

        queries = new Queries(model, environment);
        executor = new Executor(model, queries, environment);
        env = environment;

        this.init();
    }

    private function init() { throw new Error('Not implemented!'); }


    @:final
    public function fromDump(dump:Dynamic):Void
    {
        ActionLog._loggingEnabled = false;

        model.fromDump(dump);

        ActionLog._loggingEnabled = true;
    }

    @:final
    public function toDump():Dynamic
    {
        return model.toDump();
    }

    @:final
    #if debug
    public function execute(name:String, params:Dynamic, ?hashToCheck:String):Dynamic
    #else
    public function execute(name:String, params:Dynamic, ?hashToCheck:Float):Dynamic
    #end
    {
        var result:CommandResult = {
            name: null,
            params: null,
            changes: null,
            exchangables: null,
            error: null,
            #if debug
            hash: null
            #else
            hash: Math.NaN
            #end
        }

        try
        {
            result.name = name;
            result.params = params;

            executor.executeExternal(name, params);

            #if debug // проверяем строковый хэш
            result.hash = ActionLog.calculateChangeHash();

            if (hashToCheck != null && hashToCheck != result.hash)
            {
                throw new Error("long_hash_mismatch\nclient:\n" + hashToCheck +  "\nserver:\n" + result.hash);
            }

            #else // проверяем числовой хэш

            result.hash = model.__hash;

            if (hashToCheck != null && hashToCheck != result.hash)
            {
                throw new Error("short_hash_mismatch");
            }
            #end

            result.changes = ActionLog.commit();
            result.exchangables = env.commit();
        }
        catch(error:Error)
        {
            ActionLog.rollback();
            env.rollback();

            result.error = error.message;
        }
        catch(error:Dynamic)
        {
            ActionLog.rollback();
            env.rollback();

            #if (js || flash)
            result.error = untyped String(error);
            #else
            result.error = Std.string(error);
            #end
        }

        return result;
    }

    @:final
    public function query(queryName:String, ?params:Dynamic):Dynamic
    {
        var result:Dynamic = { result: null, error: null };

        try
        {
            result.result = queries.runExternal(queryName, params);
        }
        catch(err:Dynamic)
        {
            result.error = err;
        }

        return result;
    }
}

typedef CommandResult = {
    public var name:String;
    public var params:Dynamic;
    public var changes:Array<ActionDump>;
    public var exchangables:Array<Dynamic>;
    public var error:String;
    #if debug
    public var hash:String;
    #else
    public var hash:Float;
    #end
}

typedef QueryResult = {
    public var name:String;
    public var result:Dynamic;
}
