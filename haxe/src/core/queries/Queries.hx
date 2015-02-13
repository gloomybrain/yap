package core.queries;

import haxe.macro.ExprTools;
import haxe.macro.Expr;
import haxe.macro.Context;
import core.macro.CommandsQueriesMacroTools;

import core.actions.ActionLog;
import core.queries.BaseQuery;

@:final
class Queries<T>
{
    private var _environment:Environment;

    private var _externalQueryClasses:Map<String, Dynamic>;

    private var _numOfRunningQueries(default, set):Int;

    private var _model:T;

    private var _extQueries:Map<String, Void -> BaseQuery<T>>;

    public function new(model:T, environment:Environment)
    {
        _environment = environment;
        _model = model;
        _externalQueryClasses = new Map<String, BaseQuery<T>>();
        _extQueries = new Map();
        _numOfRunningQueries = 0;
    }

    macro public function addExternal(contextExpr:Expr, queryNameExpr:Expr, queryClassExpr:Expr):Expr
    {
        var newCmd:String = CommandsQueriesMacroTools.getQueryCreationCode(contextExpr, queryClassExpr);
        var ctxName:String = CommandsQueriesMacroTools.getContextName(contextExpr);
        var funName:String = ExprTools.toString(queryNameExpr);

        var code:String = '${ctxName}.__addExt(${funName}, function(){ return ${newCmd}; })';

        return Context.parse(code, Context.currentPos());
    }

    @:noCompletion
    public function __addExt(qrName:String, constructor:Void -> BaseQuery<T>):Void
    {
        _extQueries[qrName] = constructor;
    }

    @:generic
    @:noCompletion
    public inline function __getQry<C:ConstructableQuery>():C
    {
        return new C(_model, this, _environment);
    }

    public function runExternal(name:String, ?params:Dynamic):Dynamic
    {
        var query:BaseQuery<T> = _extQueries[name]();

        return this.__run(query, params);
    }

    macro public function run(contextExpr:Expr, queryClassExpr:Expr, queryArgs:Expr):Expr
    {
        var newQuery:String = CommandsQueriesMacroTools.getQueryCreationCode(contextExpr, queryClassExpr);
        var ctxName:String = CommandsQueriesMacroTools.getContextName(contextExpr);
        var args:String = ExprTools.toString(queryArgs);

        var code:String = '${ctxName}.__run(${newQuery}, ${args})';

        return Context.parse(code, Context.currentPos());
    }

    @:noCompletion
    public function __run(query:BaseQuery<T>, params:Dynamic = null):Dynamic
    {
        _numOfRunningQueries++;

        var result:Dynamic;

        // обрабатываем ошибку в запросе и его вложенных запросах
        // вызов первого запроса делаем в try...catch, чтобы поймать возможную ошибку
        // вызов вложенных запросов (которые может запустить первый) и так будут в стеке первого, а значит их ошибки поймаются в этом блоке
        if(_numOfRunningQueries == 1)
        {
            try
            {
                result = query.run(params);
            }
            catch(error:Dynamic)
            {
                // цепочка запросов прервана, надо сбросить счетчик выполняющихся запросов, чтобы безопасно прокинуть ошибку наверх
                _numOfRunningQueries = 0;

                throw error;
            }
        }
        else
        {
            result = query.run(params);
        }

        _numOfRunningQueries--;

        return result;
    }

    private function set__numOfRunningQueries(value:Int):Int
    {
        ActionLog._valueWriteEnabled = value == 0;

        return _numOfRunningQueries = value;
    }
}

typedef ConstructableQuery = {
    private function new(model:Dynamic, queries:Dynamic, environment:Environment):Void;
    public function run(?params:Dynamic):Dynamic;
}
