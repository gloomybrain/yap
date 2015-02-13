package core.macro;

import haxe.macro.Expr;
import haxe.macro.Context;

@:dce

/**
* Collection of macro functions, used in Commands and Queries
**/
class CommandsQueriesMacroTools
{
    #if macro
    public static inline function getCommandCreationCode(contextExpr:Expr, commandClassExpr:Expr):String
    {
        var pos = Context.currentPos();

        var variableName:String;
        var cmdClassName:String;

        // obtain the name of valiable - instance name of this class
        variableName = getContextName(contextExpr);

        // obtain the class name of command from expression
        cmdClassName = getClassName(commandClassExpr);

        // the code uses __getCmd generic function, called with typecheck syntax (expr : type)
        // that syntax sets the type for __getCmd to class, specified in cmdClassName
        // so haxe generates __getCmd function for each class
        return '(${variableName}.__getCmd() : ${cmdClassName})';
    }

    public static inline function getQueryCreationCode(contextExpr:Expr, queryClassExpr:Expr):String
    {
        var pos = Context.currentPos();

        var variableName:String;
        var cmdClassName:String;

        // obtain the name of valiable - instance name of this class
        variableName = getContextName(contextExpr);

        // obtain the class name of command from expression
        cmdClassName = getClassName(queryClassExpr);

        // the code uses __getQry generic function, called with typecheck syntax (expr : type)
        // that syntax sets the type for __getQry to class, specified in cmdClassName
        // so haxe generates __getQry function for each class
        return '(${variableName}.__getQry() : ${cmdClassName})';
    }

    private static function getClassName(classExpr:Expr):String
    {
        var cmdClassName:String;

        // obtain the class name of command from expression
        // it could be easily achieved by using ExprTools.toString()
        // but switch-case is the only way to check argument type to be Class<T>
        switch(classExpr.expr)
        {
            case EConst(CIdent(className)):
                cmdClassName = className;

            default:
                throw new Error("Command class (Class<T>) expected!", Context.currentPos());
        }

        return cmdClassName;
    }

    public static inline function getContextName(contextExpr:Expr):String
    {
        var variableName:String;

        // obtain the name of valiable - instance name of this class
        switch(Context.typeExpr(contextExpr).expr)
        {
            case TLocal({ name: varName }):
                variableName = varName;

            case TConst(TThis):
                variableName = "this";

            case TField(_, FInstance(_, _.get() => { name: fName })):
                variableName = fName;

            default:
                throw new Error("Expected call from local variable or this, but: " + Context.typeExpr(contextExpr), Context.currentPos());
        }

        return variableName;
    }
    #end
}
