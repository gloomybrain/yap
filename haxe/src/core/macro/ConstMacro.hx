package core.macro;

#if macro

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using haxe.macro.Tools;

@:dce
class ConstMacro {
    static var anonStructId = 0;
    static var typeDefCache = new Map<String,Type>();

    static function build():Type {
        return switch (Context.getLocalType()) {
            case TInst(_.get() => {pack: ['core', 'defs'], name: "Const"}, [t]):
                createReadType(t, Context.currentPos());
            default:
                throw Context.getLocalType();
        }
    }

    static function createReadType(t:Type, pos:Position, ?pack:Array<String>, ?name:String):Type {
        switch (t) {
            case TAbstract(_.get() => {pack: [], name: "Int" | "Float" | "Bool"}, []):
                return t;

            case TInst(_.get() => {pack: [], name: "String"}, []):
                return t;

            case TInst(_.get() => {pack: [], name: "Array"}, [elemType]):
                var elemReadCT = createReadType(elemType, pos, pack, name).toComplexType();
                var readCT = macro : core.defs.ArrayRead<$elemReadCT>;
                return readCT.toType();

            case TType(_.get() => dt, []):
                var key = dt.pack.join(".") + dt.module + "." + dt.name;
                var readType = typeDefCache.get(key);
                if (readType == null) {
                    readType = createReadType(dt.type, dt.pos, dt.pack, dt.name);
                    typeDefCache.set(key, readType);
                }
                return readType;

            case TAnonymous(_.get() => (a = _)):
                if (pack == null) {
                    pack = [];
                    name = "Struct" + (++anonStructId);
                }
                return createReadStruct(a.fields, pos, pack, name);

            case TAbstract(_.get() => { pack: [], name: "Map" }, [keyType, valueType]):
                throw new Error("Do not use Map<"+keyType.toString()+", "+valueType.toString()+"> in defs, use DynamicObject<"+valueType.toString()+"> instead!", pos);

            case TAbstract(_.get() => { pack: ['core', 'defs'], name: "DynamicObject" }, [valueType]):
                var elemReadCT = createReadType(valueType, pos, pack, name).toComplexType();
                var readCT = macro : core.defs.DynamicObjectRead<$elemReadCT>;
                return readCT.toType();

            case TAbstract(_.get() => { pack: ['core', 'defs'], name: "DynamicObjectRead" }, [valueType]):
                return t;

            default:
                throw new Error('Type ${t.toString()} is not supported by Const class.', pos);
        }
    }

    static function createReadStruct(fields:Array<ClassField>, pos:Position, pack:Array<String>, name:String):Type {
        var readFields:Array<Field> = [];

        for (f in fields) {
            var readType = createReadType(f.type, f.pos, pack, name + "_" + f.name);
            readFields.push({
                name: f.name,
                pos: f.pos,
                meta: f.meta.get(),
                kind: FProp("default", "never", readType.toComplexType())
            });
        }

        var readName = "$" + name + "Read";

        Context.defineType({
            pack: pack,
            name: readName,
            pos: pos,
            kind: TDStructure,
            fields: readFields
        });

        return TPath({pack: pack, name: readName, params: []}).toType();
    }
}
#end
