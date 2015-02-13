package core.macro;

#if macro

import haxe.macro.Expr.Position;
import core.macro.UtilMacro;
import haxe.macro.TypeTools;
import haxe.macro.ComplexTypeTools;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using haxe.macro.ComplexTypeTools;

typedef PublicVarInfo =
{
    name:String,
    path:ComplexType,
    pos:Position
}

@:dce
class ValueMacro
{
    private static var ACTION_LOG:String = 'core.actions.ActionLog';
    private static var VALUE_BASE:String = 'core.models.ValueBase';
    private static var RESTRICTED:Array<String> = ['__name', '__parent', '__hash', '__isRooted', 'reset'];
    private static var COLLECTIONS:Array<String> = ['ValueMap', 'ValueArray'];
    private static var BASE_PACKAGE:Array<String> = ['core', 'models', 'collections'];


    public static function build():Array<Field>
    {
        var fields = haxe.macro.Context.getBuildFields();
        var fieldNamesToRemove:Array<String> = [];
        var fieldsToAdd:Array<Field> = [];
        var publicVars:Array<PublicVarInfo> = [];

        for (field in fields)
        {
            if (field.access.indexOf(AStatic) != -1)
                Context.fatalError('Static fields are not allowed!', field.pos);

            if (RESTRICTED.indexOf(field.name) != -1)
                Context.fatalError('Field named ${field.name} could not be declared!', field.pos);

            if (field.access.indexOf(APublic) == -1)
                continue;

            switch (field.kind)
            {
                case FVar(tPath, _):
                    processVar(field, fieldNamesToRemove, fieldsToAdd, publicVars);
                case FFun(_):
                    processFun(field, fields, fieldNamesToRemove, fieldsToAdd);
                case FProp(_):
                default:
                    Context.fatalError('Unsupported field kind: ' + field.kind, field.pos);
            }
        }

        // removing public vars
        fields = filterFieldsByName(fields, fieldNamesToRemove);

        // adding properties instead
        for (field in fieldsToAdd) fields.push(field);

        fields.push(genFromDump(publicVars, Context.currentPos()));
        fields.push(genToDump(publicVars, Context.currentPos()));
        fields.push(genSetRooted(publicVars, Context.currentPos()));
        fields.push(genResetField(publicVars, Context.currentPos()));

        return fields;
    }

    private static function getValidCollectionTPath(tPath:ComplexType):ComplexType
    {
        var t:Type = ComplexTypeTools.toType(tPath);

        // extract type param from TPath
        var typeParam:ComplexType;
        switch(tPath)
        {
            case TPath(_ => { params: [TPType(tp)] }): typeParam = tp;
            default: Context.fatalError("TPath with one parameter expected.", Context.currentPos());
        }

        // create TPath with valid pack from
        switch(t)
        {
            case TAbstract(_.get() => aType, params):
                var validType = TPath({name: aType.name, pack: aType.pack, params: [TPType(typeParam)]});
                return validType;

            default:
                Context.fatalError("TAbstract expected.", Context.currentPos());
        }

        // this return will never happen
        return tPath;
    }

    private static function processVar(
        field:Field,
        fieldNamesToRemove:Array<String>,
        fieldsToAdd:Array<Field>,
        publicVars:Array<PublicVarInfo>):Void
    {
        switch (field.kind)
        {
            case FVar(fieldTPath, _):

                // collections (ValueMap, ValueArray) need to have fixed TPath with valid pack
                if(tPathIsCollection(fieldTPath, field.pos))
                    fieldTPath = getValidCollectionTPath(fieldTPath);

                assertLegalTPath(fieldTPath, field.pos);

                publicVars.push({name: field.name, path: fieldTPath, pos: field.pos});

                // remove plain var
                fieldNamesToRemove.push(field.name);

                // add property
                fieldsToAdd.push({
                    kind: FProp(
                        'default',
                        'set',
                        fieldTPath,
                        Context.parse(UtilMacro.genDefaultValue(fieldTPath, field.pos), field.pos)
                    ),
                    meta: [],
                    name: field.name,
                    doc: null,
                    pos: field.pos,
                    access: [APublic]
                });

                var code = genSetterCode(field.name, fieldTPath, field.pos);

                // add setter
                fieldsToAdd.push({
                    kind: FFun(
                        {
                            args: [ {name: 'value', type: fieldTPath, opt: false, value: null} ],
                            params: [],
                            ret: fieldTPath,
                            expr: Context.parse(code, field.pos)
                        }
                    ),
                    meta: [],
                    name: 'set_' + field.name,
                    doc: null,
                    pos: field.pos,
                    access: [APublic]
                });

            default:
                Context.fatalError('FVar exprected!', field.pos);
        }
    }

    private static function processFun(
        field:Field,
        fields:Array<Field>,
        fieldNamesToRemove:Array<String>,
        fieldsToAdd:Array<Field>
    ):Void
    {
        switch (field.kind)
        {
            case FFun(func):
                if (field.name.indexOf('set_') == 0)
                {
                    var propName = field.name.substring(4);

                    for (f in fields)
                    {
                        if ((propName == field.name) && (f.access.indexOf(APublic) != -1)) switch (f.kind)
                        {
                            case FVar(_):
                                Context.fatalError('set_$propName method is to be generated!', field.pos);
                            default:
                                continue;
                        }
                    }
                }
            default:
                Context.fatalError('FFun expected!', field.pos);
        }
    }

    private static function genResetField(publicVars:Array<PublicVarInfo>, pos:Position):Field
    {
        var code = '';

        code += '{';

        for (pVar in publicVars)
        {
            code += 'this.${pVar.name} = ${UtilMacro.genDefaultValue(pVar.path, pos)};';
        }

        code += '}';

        return {
            access: [APrivate, AOverride],
            name: 'reset',
            meta: null,
            pos: pos,
            kind: FFun({
                args: [],
                expr: Context.parse(code, pos),
                ret: null
            })
        };
    }

    private static function genSetterCode(fieldName, fieldTPath, pos):String
    {
        var changeClsName = 'Change';

        switch (fieldTPath)
        {
            case TPath(path):
                changeClsName = genChangeType(fieldName, fieldTPath, pos);
            default:
                Context.fatalError('TPath expected in genSetterCode', pos);
        }

        var code = '{';

        code += 'if (!$ACTION_LOG._valueWriteEnabled)';
        code += '{';
        code += 'throw new Error("Unable to write value!");';
        code += '}';

        code += 'if(${UtilMacro.genComparsionCode('this.$fieldName', 'value', fieldTPath, pos)})';
        code += '{';
        code += 'return value;';
        code += '}';

        code += 'var oldValue = this.$fieldName;';

        if (!UtilMacro.tPathIsSimple(fieldTPath, pos))
        {
            code += 'if (this.$fieldName != null)';
            code += '{';
            code += 'this.$fieldName.__name = null;';
            code += 'this.$fieldName.__parent = null;';
            code += 'this.$fieldName.setRooted(false);';
            code += '}';
            code += 'if (value != null)';
            code += '{';
            code += 'if (value.__parent != null) { throw new Error("Unable to re-parent value!"); }';
            code += 'value.__parent = this;';
            code += 'value.__name = "$fieldName";';
            code += 'value.setRooted(this.__isRooted);';
            code += '}';
        }

        code += UtilMacro.genUpdateHashCode(fieldTPath, 'oldValue', 'value', pos);

        code += 'this.$fieldName = value;';
        code += 'if ($ACTION_LOG._loggingEnabled && this.__isRooted) {';
        code += 'var change = new $changeClsName(this, "$fieldName", oldValue, value);';
        code += '$ACTION_LOG._actions.push(change);';
        code += '}';
        code += 'return value;';
        code += '}';

        return code;
    }

    private static function tPathSubsValueBase(typePath:ComplexType, pos:Position):Bool
    {
        switch (typePath)
        {
            case TPath(path):

                var typeName = UtilMacro.getFullComplexTypeName(typePath, pos);
                var type = Context.getType(typeName);

                if (type == null)
                    Context.fatalError('Type not found: $typeName', pos);

                return typeSubsValueBase(type, pos);

            default:
                Context.fatalError('Type can not extend $VALUE_BASE\n$typePath', pos);
        }

        return false;
    }

    private static function typeSubsValueBase(type:Type, pos:Position):Bool
    {
        switch(type)
        {
            case TInst(ref, _):
                var clsType = ref.get();
                var superClassDef = clsType.superClass;

                if (superClassDef != null)
                {
                    var superClass = superClassDef.t.get();
                    var superClassType = TPath({pack: superClass.pack, name: superClass.name}).toType();

                    var superClassPack = superClass.pack.slice(0);
                    superClassPack.push(superClass.name);
                    var superClassFullName = superClassPack.join('.');

                    return (superClassFullName == VALUE_BASE) || typeSubsValueBase(superClassType, pos);
                }

            default:
                Context.warning("Type " + type + " is not subclass of ValueBase.", pos);
                return false;
        }

        return false;
    }

    private static function filterFieldsByName(source:Array<Field>, deprecated:Array<String>):Array<Field>
    {
        var result:Array<Field>;

        if (deprecated.length > 0)
        {
            result = [];

            for (field in source)
            {
                var found = false;

                for (name in deprecated)
                {
                    if (name == field.name)
                    {
                        found = true;
                        break;
                    }
                }

                if (!found) result.push(field);
            }
        }
        else
        {
            result = source;
        }

        return result;
    }

    private static function genFromDump(publicVars:Array<PublicVarInfo>, pos:Position):Field
    {
        var code = '{';

        code += 'this.reset();';

        for (pv in publicVars)
        {
            code += 'if (!Reflect.hasField(dump, "${pv.name}"))';
            code += '{';
            code += 'throw new Error("Field ${pv.name} not found in dump!");';
            code += '}';

            if (UtilMacro.tPathIsSimple(pv.path, pv.pos))
            {
                code += 'this.${pv.name} = dump.${pv.name};';
            }
            else
            {
                // start of null check for nullable types
                code += 'if (dump.${pv.name} == null)';
                code += '{';
                code += 'this.${pv.name} = null;';
                code += '}';
                code += 'else';
                code += '{';

                var typeName = UtilMacro.getFullComplexTypeName(pv.path, pv.pos);

                if(tPathIsCollection(pv.path, pv.pos))
                {
                    code += 'var ${pv.name} = new $typeName(${createCollectionConstructionCode(pv)});';
                }
                else
                {
                    code += 'var ${pv.name} = new $typeName();';
                }

                code += '${pv.name}.fromDump(dump.${pv.name});';
                code += 'this.${pv.name} = ${pv.name};';

                // end of null check for nullable types
                code += '}';
            }
        }

        code += 'this.init();';
        code += '}';

        return {
            kind: FFun({
                    args: [{
                        name: 'dump',
                        type: TPath({ name: 'Dynamic', pack: [], params: [] }),
                        opt: false,
                        value: null
                    }],
                    params: [],
                    ret: null,
                    expr: Context.parse(code, pos)
            }),
            meta: [],
            name: 'fromDump',
            doc: null,
            pos: pos,
            access: [APublic, AOverride]
        };
    }

    private static function createCollectionConstructionCode(variable:PublicVarInfo):String
    {
        switch(variable.path)
        {
            case TPath(_ => path = { name: 'ValueMap', params: [TPType(paramType = TPath(paramPath))] }):
                return 'new core.models.collections.ValueMapImpl<${paramPath.name}>()';

            case TPath(_ => path = { name: 'ValueArray', params: [TPType(paramType = TPath(paramPath))] }):
                return 'new core.models.collections.ValueArrayImpl<${paramPath.name}>()';

            default:
                throw new Error('Cannot create construction collection of ${variable.path}!', variable.pos);
        }
    }

    private static function genToDump(publicVars:Array<PublicVarInfo>, pos:Position):Field
    {
        var code = '{';
        code += 'return {';

        var first = true;
        for (pv in publicVars)
        {
            if (first)
            {
                first = false;
            }
            else
            {
                code += ', ';
            }

            if (UtilMacro.tPathIsSimple(pv.path, pv.pos))
            {
                code += '${pv.name}: this.${pv.name}';
            }
            else
            {
                code += '${pv.name}: (${pv.name} == null ? null : ${pv.name}.toDump())';
            }
        }

        code += '};'; // end of return
        code += '}'; // end of method body

        return {
            kind: FFun({
                args: [],
                ret: TPath({ name: 'Dynamic', pack: [], params: [] }),
                expr: Context.parse(code, pos)
            }),
            name: 'toDump',
            pos: pos,
            access: [APublic, AOverride]
        };
    }

    private static function genSetRooted(publicVars:Array<PublicVarInfo>, pos:Position):Field
    {
        var code = '';

        code += '{';

        code += 'if (this.__isRooted == value) return;';
        code += 'this.__isRooted = value;';

        for (pv in publicVars)
        {
            if (!UtilMacro.tPathIsSimple(pv.path, pv.pos))
            {
                code += 'if (this.${pv.name} != null) this.${pv.name}.setRooted(value);';
            }
        }

        code += '}';

        return {
            kind: FFun({
                args: [{
                    name: 'value',
                    type: TPath({ name: 'Bool', pack: [], params: [] }),
                    opt: false,
                    value: null
                }],
                expr: Context.parse(code, pos),
                ret: null
            }),
            name: 'setRooted',
            pos: pos,
            access: [APrivate, AOverride]
        };
    }

    private static function genChangeType(fieldName:String, fieldTPath:ComplexType, pos:Position):String
    {
        var localClassRef = Context.getLocalClass();
        var localClass = localClassRef.get();

        // possible bug with ignoring type parameters (params is empty, but it can be non-empty)
        var localClassTPath = TPath({pack: localClass.pack, name: localClass.name, params: []});

        var changeClsName = 'Change${localClass.name}_$fieldName';
        var keyTPath = TPath({pack: [], name: 'String'});
        var superClassTypePath = {
            pack: ['core', 'actions'],
            name: 'ChangeBase',
            params: [
                TPType(localClassTPath),
                TPType(fieldTPath),
                TPType(keyTPath)
            ]
        };
        var superClassTPath = TPath(superClassTypePath);

        var newValueString = '(_newValue == null ? null : _newValue.toDump())';
        if (UtilMacro.tPathIsSimple(fieldTPath, pos)) newValueString = '_newValue';

        Context.defineType({
            pack: localClass.pack,
            name: changeClsName,
            pos: pos,
            meta: [],
            kind: TDClass(superClassTypePath, [], false),
            fields: [
                {
                    access: [APublic],
                    name: 'new',
                    kind: FFun({
                        args: [
                            { name: 'model', type: localClassTPath },
                            { name: 'key', type: keyTPath },
                            { name: 'oldValue', type: fieldTPath },
                            { name: 'newValue', type: fieldTPath },
                            { name: 'opName', type: TPath({pack: [], name: 'String'}), value: macro 'var' }
                        ],
                        expr: Context.parse('{ super(model, key, oldValue, newValue, opName); }', pos),
                        params: [],
                        ret: null
                    }),
                    pos: pos
                },
                {
                    access: [APublic, AOverride],
                    name: 'rollback',
                    kind: FFun({
                        args: [],
                        expr: Context.parse('{ _model.$fieldName = _oldValue; }', pos),
                        params: [],
                        ret: null
                    }),
                    pos: pos
                },
                {
                    access: [APublic, AOverride],
                    name: 'toDump',
                    kind: FFun({
                        args: [],
                        expr: Context.parse(
                            '{ return { '+
                            'path: _path' +
                            ', newValue: $newValueString' +
                            ', opName: this.opName' +
                            '}; }',
                            pos
                        ),
                        params: [],
                        ret: TPath({pack: ['core', 'actions'], name: 'ActionDump'})
                    }),
                    pos: pos
                }
            ]
        });

        return changeClsName;
    }

    private static function getTypeParamTPath(typeParam:TypeParam, pos:Position):ComplexType
    {
        switch (typeParam)
        {
            case TPType(tPath):
                return tPath;
            default:
                Context.fatalError('TPType expected in getTypeParamTPath, got $typeParam', pos);
        }

        return null;
    }

    private static function assertLegalTPath(typePath:ComplexType, pos:Position):Void
    {
        if (UtilMacro.tPathIsSimple(typePath, pos)) return;
        if (tPathIsCollection(typePath, pos)) return;
        if (tPathSubsValueBase(typePath, pos)) return;

        Context.fatalError('Type must be $VALUE_BASE or any simple type!', pos);
    }

    private static function assertNoConstructorArgs(field:Field):Void
    {
        switch (field.kind)
        {
            case FFun(func):
                for (arg in func.args)
                {
                    Context.fatalError('Constructor shouldn\'t have any arguments!', field.pos);
                }

            default:
                Context.fatalError('Field "new" must be a function!', field.pos);
        }
    }

    private static function tPathIsCollection(typePath:ComplexType, pos:Position):Bool
    {
        switch(typePath)
        {
            case TPath(_ => { name: 'ValueMap' | 'ValueArray', params: [TPType(paramTypePath)] }):
                assertLegalTPath(paramTypePath, pos);
                return true;

            default:
                return false;
        }
    }

}
#end
