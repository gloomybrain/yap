package core.macro;

#if macro

import haxe.macro.Expr.ComplexType;
import haxe.macro.TypeTools;
import haxe.macro.ComplexTypeTools;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using haxe.macro.ComplexTypeTools;

typedef TypeNameInfo =
{
    typeName:String,
    typeParams:Array<TypeNameInfo>
}

class UtilMacro
{
    public static function tPathIsSimple(tPath:ComplexType, pos:Position):Bool
    {
        var simpleTypeNames = ['Bool', 'Int', 'Float', 'String', 'StdTypes'];

        var result = switch (tPath)
        {
            case TPath(path): (simpleTypeNames.indexOf(path.name) != -1 && path.pack.length == 0);
            default: false;
        }

        return result;
    }

    public static function getCompexTypeNameInfo(tPath:ComplexType, pos:Position):TypeNameInfo
    {
        var type:Type = ComplexTypeTools.toType(tPath);

        return UtilMacro.getTypeNameInfo(type, pos);
    }

    public static function getTypeNameInfo(type:Type, pos:Position):TypeNameInfo
    {
        var result:TypeNameInfo = { typeName: null, typeParams:null };

        switch (type)
        {
            case TAbstract(typeRef, params):
                var type = typeRef.get();
                var pack = type.pack;
                pack.push(type.name);

                result.typeName = pack.join('.');

                if (params != null)
                {
                    result.typeParams = new Array<TypeNameInfo>();

                    for (p in params)
                    {
                        result.typeParams.push(getTypeNameInfo(p, pos));
                    }
                }

            case TInst(typeRef, params):
                var type = typeRef.get();
                var pack = type.pack;
                pack.push(type.name);

                result.typeName = pack.join('.');

                if (params != null)
                {
                    result.typeParams = new Array<TypeNameInfo>();

                    for (p in params)
                    {
                        result.typeParams.push(getTypeNameInfo(p, pos));
                    }
                }

            case TDynamic(_):
                result.typeName = 'Dynamic';

            default:
                Context.fatalError('Failed to UtilMacro.getTypeNameInfo for $type!', pos);
        }

        return result;
    }

    public static function getFullComplexTypeName(typePath:ComplexType, pos:Position):String
    {
        var type:Type = ComplexTypeTools.toType(typePath);

        return UtilMacro.getFullTypeName(type, pos);
    }

    public static function getFullTypeName(type:Type, pos:Position):String
    {
        var result = '';

        switch (type)
        {
            case TAbstract(_.get() => { pack: p, module: m, name: n }, params):
                p.push(n);
                result = p.join('.');

            case TInst(_.get() => { pack: p, module: m, name: n }, params):
                p.push(n);
                result = p.join('.');

            case TDynamic(_):
                result = "Dynamic";

            default:
                Context.fatalError('Failed to getFullTypeName for $type, type= $type!', pos);
        }

        return result;
    }

    public static function genUpdateHashCode(fieldTPath:ComplexType, oldValue:String, newValue:String, pos:Position):String
    {
        if (!UtilMacro.tPathIsSimple(fieldTPath, pos))
        {
            return 'this.updateHash(this.hashOfValueBase($oldValue), this.hashOfValueBase($newValue));';
        }

        switch(fieldTPath)
        {
            case TPath(path):
                switch(path.name)
                {
                    case 'Bool':
                        return 'this.updateHash(this.hashOfBool($oldValue), this.hashOfBool($newValue));';
                    case 'Int':
                        return 'this.updateHash(this.hashOfInt($oldValue), this.hashOfInt($newValue));';
                    case 'Float':
                        return 'this.updateHash(this.hashOfFloat($oldValue), this.hashOfFloat($newValue));';
                    case 'String':
                        return 'this.updateHash(this.hashOfString($oldValue), this.hashOfString($newValue));';
                    default:
                        Context.fatalError('Unexpected simple type ${path.name}!', pos);
                }
            default:
                Context.fatalError('Expected TPath in genUpdateHashCode, got $fieldTPath', pos);
        }

        return '';
    }

    public static function normalizeTPath(tPath:ComplexType, pos:Position):ComplexType
    {
        switch(tPath)
        {
            case TPath(path):
                return TPath({pack: path.pack, name: (path.sub == null ? path.name : path.sub)});
            default:
                Context.fatalError('TPath expected in normalizeTPath', pos);
        }

        return tPath;
    }

    public static function tPathIsNullable(tPath:ComplexType, pos:Position):Bool
    {
        var cType = normalizeTPath(tPath, pos);

        if (!tPathIsSimple(tPath, pos)) return true;

        var result = switch (cType)
        {
            case TPath(path): (path.name == 'String') && path.pack.length == 0;
            default: false;
        }

        return result;
    }

    public static function genDefaultValue(elementCT:ComplexType, pos:Position):String
    {
        var normElementCT = normalizeTPath(elementCT, pos);

        switch(normElementCT)
        {
            case TPath({pack: [], name: 'Bool'}): return 'false';
            case TPath({pack: [], name: 'Int'}): return '0';
            case TPath({pack: [], name: 'UInt'}): return '0';
            case TPath({pack: [], name: 'Float'}): return '0';

            default: return 'null';
        }
    }

    public static function genComparsionCode(left:String, right:String, elementCT:ComplexType, pos:Position):String
    {
        var normElementCT = normalizeTPath(elementCT, pos);

        var result = switch(normElementCT)
        {
            case TPath({pack: [], name: 'Float'}):
                '(Math.isNaN($left) && Math.isNaN($right)) || (${UtilMacro.genPlatfromDependedComparsionCode(left, right)})';

            default: UtilMacro.genPlatfromDependedComparsionCode(left, right);
        }

        return result;
    }

    private static function genPlatfromDependedComparsionCode(left:String, right:String):String
    {
        if (Context.defined('cs'))
        {
            return 'cs.internal.Runtime.eq($left, $right)';
        }

        return '$left == $right';
    }
}
#end