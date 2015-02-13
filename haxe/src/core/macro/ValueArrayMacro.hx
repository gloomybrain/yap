package core.macro;

#if macro

import haxe.macro.Context;
import haxe.macro.TypeTools;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.ComplexTypeTools;

using haxe.macro.Tools;
using haxe.macro.ComplexTypeTools;

class ValueArrayMacro
{
    private static var ACTION_LOG = 'core.actions.ActionLog';
    private static var CHANGE_OP = 'core.actions.ChangeOp';
    private static var _pack = ['core', 'models', 'collections'];
    private static var performing = false;

    public static function build():Type
    {
        var localType:Type = Context.getLocalType();

        if (performing) return localType;
        performing = true;

        var pos = Context.currentPos();

        switch(localType)
        {
            case TInst(_.get() => { pack: _pack, name: 'ValueArrayImpl' }, [elementType]):
                var result = genSubTypeFor(elementType, pos);
                performing = false;
                return result;

            default:
                Context.fatalError('ValueArrayMacro.build() can be called only on ValueArrayImpl!', pos);
        }

        // this will never happen
        return localType;
    }

    private static function genSubTypeFor(elementType:Type, pos:Position):Type
    {
        var elementComplexType = elementType.toComplexType();
        var normalizedElementType = UtilMacro.normalizeTPath(elementComplexType, pos);
        var elementTypeName = UtilMacro.getFullComplexTypeName(normalizedElementType, pos);
        var typeName = 'ValueArray_of_' + elementTypeName.split('.').join('_');
        var fullTypeName = _pack.join('.') + '.$typeName';

        // try to get the type
        try
        {
            return Context.getType(fullTypeName);
        }
        catch(error:Dynamic)
        {
            // the type needs to be defined
        }

        var elementComplexType = elementType.toComplexType();
        var fields:Array<Field> = [
            {
                pos: pos,
                access: [APrivate, AOverride],
                name: 'setRooted',
                kind: FFun(genArraySetRootedFun(normalizedElementType, pos))
            },
            {
                pos: pos,
                access: [APublic, AOverride],
                name: 'set',
                kind: FFun(genArraySetFun(normalizedElementType, pos))
            },
            {
                pos: pos,
                access: [APublic, AOverride],
                name: 'push',
                kind: FFun(genArrayPushFun(normalizedElementType, pos))
            },
            {
                pos: pos,
                access: [APublic, AOverride],
                name: 'pop',
                kind: FFun(genArrayPopFun(normalizedElementType, pos))
            },
            {
                pos: pos,
                access: [APublic, AOverride],
                name: 'shift',
                kind: FFun(genArrayShiftFun(normalizedElementType, pos))
            },
            {
                pos: pos,
                access: [APublic, AOverride],
                name: 'unshift',
                kind: FFun(genArrayUnshiftFun(normalizedElementType, pos))
            },
            {
                pos: pos,
                access: [APublic, AOverride],
                name: 'insert',
                kind: FFun(genArrayInsertFun(normalizedElementType, pos))
            },
            {
                pos: pos,
                access: [APublic, AOverride],
                name: 'remove',
                kind: FFun(genArrayRemoveFun(normalizedElementType, pos))
            },
            {
                pos: pos,
                access: [APublic, AOverride],
                name: 'fromDump',
                kind: FFun(genArrayFromDumpFun(normalizedElementType, pos))
            },
            {
                pos: pos,
                access: [APublic, AOverride],
                name: 'toDump',
                kind: FFun(genArrayToDumpFun(normalizedElementType, pos))
            }
        ];

        Context.defineType({
            pos: pos,
            pack: _pack,
            name: typeName,
            kind: TDClass({ pack: _pack, name: 'ValueArrayBase', params: [TPType(elementComplexType)] }, [], false),
            fields: fields
        });

        return Context.getType(fullTypeName);
    }

    private static function genArraySetRootedFun(elementComplexType:ComplexType, pos:Position):Function
    {
        var code = '';

        code += '{';

        code += 'if (this.__isRooted == value) return;';
        code += 'this.__isRooted = value;';

        if (!UtilMacro.tPathIsSimple(elementComplexType, pos))
        {
            code += 'for (element in _data)';
            code += '{';
            code += 'if (element != null) element.setRooted(value);';
            code += '}';
        }

        code += '}';

        return {
            args: [
                {
                    name: 'value',
                    type: TPath({pack: [], name: 'Bool'})
                }
            ],
            expr: Context.parse(code, pos),
            ret: null
        };
    }

    private static function genArraySetFun(elementComplexType:ComplexType, pos:Position):Function
    {
        var changeClsName = genIndexChangeType(elementComplexType, pos);

        var code = '';

        code += '{';

        code += 'this.assertWriteEnabled();';

        code += 'if (index < 0) throw new Error("Index must be >= 0!");';
        code += 'if (_data.length < index) throw new Error("Unable to set - index is out of bounds!");';

        code += 'if (_data.length == index)';
        code += '{';
        code += 'this.push(value);';
        code += 'return;';
        code += '}';

        code += 'if (${UtilMacro.genComparsionCode('_data[index]', 'value', elementComplexType, pos)}) return;';

        code += 'var oldValue = _data[index];';

        if (!UtilMacro.tPathIsSimple(elementComplexType, pos))
        {
            code += 'this.removeParent(oldValue);';
            code += 'if (oldValue != null) oldValue.setRooted(false);';

            code += 'this.addParent(value, index);';
            code += 'if (value != null) value.setRooted(this.__isRooted);';
        }

        code += '_data[index] = value;';

        code += UtilMacro.genUpdateHashCode(elementComplexType, 'oldValue', 'value', pos);
        code += 'if ($ACTION_LOG._loggingEnabled && this.__isRooted) {';
        code += 'var change = new $changeClsName(this, index, oldValue, value);';
        code += '$ACTION_LOG._actions.push(change);';
        code += '}';

        code += '}';

        return {
            args: [
                {
                    name: 'index',
                    type: TPath({pack: [], name: 'Int'})
                },
                {
                    name: 'value',
                    type: elementComplexType
                }
            ],
            expr: Context.parse(code, pos),
            ret: null
        };
    }

    private static function genIndexChangeType(elementCT:ComplexType, pos:Position):String
    {
        var normElementCT = UtilMacro.normalizeTPath(elementCT, pos);
        var elementTypeName = UtilMacro.getFullComplexTypeName(elementCT, pos);
        var containerTypeName = 'ValueArray_of_' + elementTypeName.split('.').join('_');
        var changeTypeName = 'IndexChange$containerTypeName';

        var baseContainerTPath = TPath({ pack: _pack, name: 'ValueArrayBase', params: [TPType(elementCT)] });

        var rollbackCode = '{ _model.set(_key, _oldValue); }';

        var fields:Array<Field> = [];

        addChangeConstructor(fields, baseContainerTPath, normElementCT, '$CHANGE_OP.INDEX', pos);
        addChangeRollback(fields, rollbackCode, pos);
        addChangeToDump(fields, normElementCT, pos);

        defineChangeType(changeTypeName, baseContainerTPath, normElementCT, fields, pos);

        return '${_pack.join(".")}.$changeTypeName';
    }

    private static function genArrayPushFun(elementComplexType:ComplexType, pos:Position):Function
    {
        var changeClsName = genPushChangeType(elementComplexType, pos);
        var defaultOldValue = UtilMacro.genDefaultValue(elementComplexType, pos);

        var code = '';

        code += '{';

        code += 'this.assertWriteEnabled();';

        code += 'var index = _data.length;';

        if (!UtilMacro.tPathIsSimple(elementComplexType, pos))
        {
            code += 'this.addParent(value, index);';
            code += 'if (value != null) value.setRooted(this.__isRooted);';
        }

        code += 'var result = _data.push(value);';

        code += UtilMacro.genUpdateHashCode(elementComplexType, defaultOldValue, 'value', pos);
        code += 'if ($ACTION_LOG._loggingEnabled && this.__isRooted) {';
        code += 'var change = new $changeClsName(this, index, $defaultOldValue, value);';
        code += '$ACTION_LOG._actions.push(change);';
        code += '}';

        code += 'return result;';

        code += '}';

        return {
            args: [{ name: 'value', type: elementComplexType }],
            expr: Context.parse(code, pos),
            ret: TPath({pack: [], name: 'Int'})
        };
    }

    private static function genPushChangeType(elementCT:ComplexType, pos:Position):String
    {
        var normElementCT = UtilMacro.normalizeTPath(elementCT, pos);
        var elementTypeName = UtilMacro.getFullComplexTypeName(elementCT, pos);
        var containerTypeName = 'ValueArray_of_' + elementTypeName.split('.').join('_');
        var changeTypeName = 'PushChange$containerTypeName';

        var baseContainerTPath = TPath({ pack: _pack, name: 'ValueArrayBase', params: [TPType(elementCT)] });

        var rollbackCode = '{ _model.pop(); }';

        var fields:Array<Field> = [];

        addChangeConstructor(fields, baseContainerTPath, normElementCT, '$CHANGE_OP.PUSH', pos);
        addChangeRollback(fields, rollbackCode, pos);
        addChangeToDump(fields, normElementCT, pos);

        defineChangeType(changeTypeName, baseContainerTPath, normElementCT, fields, pos);

        return '${_pack.join(".")}.$changeTypeName';
    }

    private static function genArrayPopFun(elementComplexType:ComplexType, pos:Position):Function
    {
        var changeClsName = genPopChangeType(elementComplexType, pos);
        var defaultValue = UtilMacro.genDefaultValue(elementComplexType, pos);

        var code = '';

        code += '{';

        code += 'this.assertWriteEnabled();';
        code += 'if (_data.length == 0) throw new Error("Unable to preform pop on an empty array!");';

        code += 'var index = _data.length - 1;';
        code += 'var oldValue = _data.pop();';

        if (!UtilMacro.tPathIsSimple(elementComplexType, pos))
        {
            code += 'this.removeParent(oldValue);';
            code += 'if (oldValue != null) oldValue.setRooted(false);';
        }

        code += UtilMacro.genUpdateHashCode(elementComplexType, 'oldValue', defaultValue, pos);
        code += 'if ($ACTION_LOG._loggingEnabled) {';
        code += 'var change = new $changeClsName(this, index, oldValue, $defaultValue);';
        code += '$ACTION_LOG._actions.push(change);';
        code += '}';

        code += 'return oldValue;';

        code += '}';

        return {
            args: [],
            expr: Context.parse(code, pos),
            ret: elementComplexType
        };
    }

    private static function genPopChangeType(elementCT:ComplexType, pos:Position):String
    {
        var normElementCT = UtilMacro.normalizeTPath(elementCT, pos);
        var elementTypeName = UtilMacro.getFullComplexTypeName(elementCT, pos);
        var containerTypeName = 'ValueArray_of_' + elementTypeName.split('.').join('_');
        var changeTypeName = 'PopChange$containerTypeName';

        var baseContainerTPath = TPath({ pack: _pack, name: 'ValueArrayBase', params: [TPType(elementCT)] });

        var rollbackCode = '{ _model.push(_oldValue); }';

        var fields:Array<Field> = [];

        addChangeConstructor(fields, baseContainerTPath, normElementCT, '$CHANGE_OP.POP', pos);
        addChangeRollback(fields, rollbackCode, pos);
        addChangeToDump(fields, normElementCT, pos);

        defineChangeType(changeTypeName, baseContainerTPath, normElementCT, fields, pos);

        return '${_pack.join(".")}.$changeTypeName';
    }

    private static function genArrayShiftFun(elementComplexType:ComplexType, pos:Position):Function
    {
        var changeClsName = genShiftChangeType(elementComplexType, pos);
        var defaultValue = UtilMacro.genDefaultValue(elementComplexType, pos);

        var code = '';

        code += '{';

        code += 'assertWriteEnabled();';
        code += 'if (_data.length == 0) throw new Error("Unable to preform shift on an empty array!");';

        code += 'var oldValue = _data.shift();';

        if (!UtilMacro.tPathIsSimple(elementComplexType, pos))
        {
            code += 'this.removeParent(oldValue);';
            code += 'if (oldValue != null) oldValue.setRooted(false);';

            code += 'this.reparentAll();';
        }

        code += UtilMacro.genUpdateHashCode(elementComplexType, 'oldValue', defaultValue, pos);
        code += 'if ($ACTION_LOG._loggingEnabled && this.__isRooted) {';
        code += 'var change = new $changeClsName(this, 0, oldValue, $defaultValue);';
        code += '$ACTION_LOG._actions.push(change);';
        code += '}';

        code += 'return oldValue;';

        code += '}';

        return {
            args: [],
            expr: Context.parse(code, pos),
            ret: elementComplexType
        };
    }

    private static function genShiftChangeType(elementCT:ComplexType, pos:Position):String
    {
        var normElementCT = UtilMacro.normalizeTPath(elementCT, pos);
        var elementTypeName = UtilMacro.getFullComplexTypeName(elementCT, pos);
        var containerTypeName = 'ValueArray_of_' + elementTypeName.split('.').join('_');
        var changeTypeName = 'ShiftChange$containerTypeName';

        var baseContainerTPath = TPath({ pack: _pack, name: 'ValueArrayBase', params: [TPType(elementCT)] });

        var rollbackCode = '{ _model.unshift(_oldValue); }';

        var fields:Array<Field> = [];

        addChangeConstructor(fields, baseContainerTPath, normElementCT, '$CHANGE_OP.SHIFT', pos);
        addChangeRollback(fields, rollbackCode, pos);
        addChangeToDump(fields, normElementCT, pos);

        defineChangeType(changeTypeName, baseContainerTPath, normElementCT, fields, pos);

        return '${_pack.join(".")}.$changeTypeName';
    }

    private static function genArrayUnshiftFun(elementComplexType:ComplexType, pos:Position):Function
    {
        var changeClsName = genUnshiftChangeType(elementComplexType, pos);
        var defaultValue = UtilMacro.genDefaultValue(elementComplexType, pos);

        var code = '';

        code += '{';

        code += 'this.assertWriteEnabled();';
        code += 'if (_data.length == 0) throw new Error("Unable to preform shift on an empty array!");';

        if (!UtilMacro.tPathIsSimple(elementComplexType, pos))
        {
            code += 'this.addParent(value, 0);';
            code += 'if (value != null) value.setRooted(this.__isRooted);';
        }

        code += '_data.unshift(value);';

        if (!UtilMacro.tPathIsSimple(elementComplexType, pos))
        {
            code += 'this.reparentAll();';
        }

        code += UtilMacro.genUpdateHashCode(elementComplexType, defaultValue, 'value', pos);
        code += 'if ($ACTION_LOG._loggingEnabled && this.__isRooted) {';
        code += 'var change = new $changeClsName(this, 0, $defaultValue, value);';
        code += '$ACTION_LOG._actions.push(change);';
        code += '}';

        code += '}';

        return {
            args: [{ name: 'value', type: elementComplexType }],
            expr: Context.parse(code, pos),
            ret: null
        };
    }

    private static function genUnshiftChangeType(elementCT:ComplexType, pos:Position):String
    {
        var normElementCT = UtilMacro.normalizeTPath(elementCT, pos);
        var elementTypeName = UtilMacro.getFullComplexTypeName(elementCT, pos);
        var containerTypeName = 'ValueArray_of_' + elementTypeName.split('.').join('_');
        var changeTypeName = 'UnshiftChange$containerTypeName';

        var baseContainerTPath = TPath({ pack: _pack, name: 'ValueArrayBase', params: [TPType(elementCT)] });

        var rollbackCode = '{ _model.shift(); }';

        var fields:Array<Field> = [];

        addChangeConstructor(fields, baseContainerTPath, normElementCT, '$CHANGE_OP.UNSHIFT', pos);
        addChangeRollback(fields, rollbackCode, pos);
        addChangeToDump(fields, normElementCT, pos);

        defineChangeType(changeTypeName, baseContainerTPath, normElementCT, fields, pos);

        return '${_pack.join(".")}.$changeTypeName';
    }

    private static function genArrayInsertFun(elementComplexType:ComplexType, pos:Position):Function
    {
        var changeClsName = genInsertChangeType(elementComplexType, pos);
        var defaultValue = UtilMacro.genDefaultValue(elementComplexType, pos);

        var code = '';

        code += '{';

        code += 'this.assertWriteEnabled();';

        code += 'if(index < 0) throw new Error("Index must be >= 0!");';
        code += 'if (index > _data.length) throw new Error("Unable to insert - index is out of bounds!");';

        if (!UtilMacro.tPathIsSimple(elementComplexType, pos))
        {
            code += 'this.addParent(value, index);';
            code += 'if (value != null) value.setRooted(this.__isRooted);';
        }

        code += '_data.insert(index, value);';

        if (!UtilMacro.tPathIsSimple(elementComplexType, pos))
        {
            code += 'this.reparentAll();';
        }

        code += UtilMacro.genUpdateHashCode(elementComplexType, defaultValue, 'value', pos);
        code += 'if ($ACTION_LOG._loggingEnabled && this.__isRooted) {';
        code += 'var change = new $changeClsName(this, index, $defaultValue, value);';
        code += '$ACTION_LOG._actions.push(change);';
        code += '}';

        code += '}';

        return {
            args: [
                { name: 'value', type: elementComplexType },
                { name: 'index', type: TPath({pack: [], name: 'Int' })}
            ],
            expr: Context.parse(code, pos),
            ret: null
        };
    }

    private static function genInsertChangeType(elementCT:ComplexType, pos:Position):String
    {
        var normElementCT = UtilMacro.normalizeTPath(elementCT, pos);
        var elementTypeName = UtilMacro.getFullComplexTypeName(elementCT, pos);
        var containerTypeName = 'ValueArray_of_' + elementTypeName.split('.').join('_');
        var changeTypeName = 'InsertChange$containerTypeName';

        var baseContainerTPath = TPath({ pack: _pack, name: 'ValueArrayBase', params: [TPType(elementCT)] });

        var rollbackCode = '{ _model.remove(_key); }';

        var fields:Array<Field> = [];

        addChangeConstructor(fields, baseContainerTPath, normElementCT, '$CHANGE_OP.INSERT', pos);
        addChangeRollback(fields, rollbackCode, pos);
        addChangeToDump(fields, normElementCT, pos);

        defineChangeType(changeTypeName, baseContainerTPath, normElementCT, fields, pos);

        return '${_pack.join(".")}.$changeTypeName';
    }

    private static function genArrayRemoveFun(elementComplexType:ComplexType, pos:Position):Function
    {
        var changeClsName = genRemoveChangeType(elementComplexType, pos);
        var defaultValue = UtilMacro.genDefaultValue(elementComplexType, pos);

        var code = '';

        code += '{';

        code += 'this.assertWriteEnabled();';

        code += 'if(index < 0) throw new Error("Index must be >= 0!");';
        code += 'if (index >= _data.length) throw new Error("Can not remove - index is out of bounds!");';

        code += 'var result = _data.splice(index, 1);';
        code += 'var oldValue = result[0];';

        if (!UtilMacro.tPathIsSimple(elementComplexType, pos))
        {
            code += 'this.removeParent(oldValue);';
            code += 'if (oldValue != null) oldValue.setRooted(false);';

            code += 'this.reparentAll();';
        }

        code += UtilMacro.genUpdateHashCode(elementComplexType, 'oldValue', defaultValue, pos);
        code += 'if ($ACTION_LOG._loggingEnabled && this.__isRooted) {';
        code += 'var change = new $changeClsName(this, index, oldValue, $defaultValue);';
        code += '$ACTION_LOG._actions.push(change);';
        code += '}';

        code += 'return oldValue;';

        code += '}';


        return {
            args: [{ name: 'index', type: TPath({pack: [], name: 'Int'}) }],
            expr: Context.parse(code, pos),
            ret: elementComplexType
        };
    }

    private static function genRemoveChangeType(elementCT:ComplexType, pos:Position):String
    {
        var normElementCT = UtilMacro.normalizeTPath(elementCT, pos);
        var elementTypeName = UtilMacro.getFullComplexTypeName(elementCT, pos);
        var containerTypeName = 'ValueArray_of_' + elementTypeName.split('.').join('_');
        var changeTypeName = 'RemoveChange$containerTypeName';

        var baseContainerTPath = TPath({ pack: _pack, name: 'ValueArrayBase', params: [TPType(elementCT)] });

        var rollbackCode = '{ _model.insert(_oldValue, _key); }';

        var fields:Array<Field> = [];

        addChangeConstructor(fields, baseContainerTPath, normElementCT, '$CHANGE_OP.REMOVE', pos);
        addChangeRollback(fields, rollbackCode, pos);
        addChangeToDump(fields, normElementCT, pos);

        defineChangeType(changeTypeName, baseContainerTPath, normElementCT, fields, pos);

        return '${_pack.join(".")}.$changeTypeName';
    }

    private static function genArrayFromDumpFun(elementComplexType:ComplexType, pos:Position):Function
    {
        var code = '';

        code += '{';

        code += 'this.reset();';

        code += 'for (value in dump)';
        code += '{';

        if (UtilMacro.tPathIsSimple(elementComplexType, pos))
        {
            code += 'this.push(value);';
        }
        else
        {
            code += 'if (value == null)';
            code += '{';
            code += 'this.push(null);';
            code += '}';
            code += 'else';
            code += '{';
            code += 'var v = new ${UtilMacro.getFullComplexTypeName(elementComplexType, pos)}();';
            code += 'v.fromDump(value);';
            code += 'this.push(v);';
            code += '}';
        }
        code += '}'; // for

        code += '}';

        return {
            args: [{
                name: 'dump',
                type: TPath({
                    pack: [],
                    name: 'Array',
                    params: [TPType(TPath({pack: [], name: 'Dynamic'}))]
                })
            }],
            expr: Context.parse(code, pos),
            ret: null
        };
    }

    private static function genArrayToDumpFun(elementComplexType:ComplexType, pos:Position):Function
    {
        var code = '';

        code += '{';
        code += 'var result = new Array<Dynamic>();';

        code += 'for (value in _data)';
        code += '{';

        if (UtilMacro.tPathIsSimple(elementComplexType, pos))
        {
            code += 'result.push(value);';
        }
        else
        {
            code += 'result.push(value == null ? null : value.toDump());';
        }

        code += '}'; // for

        code += 'return result;';
        code += '}';

        return {
            args: [],
            expr: Context.parse(code, pos),
            ret: TPath({pack: [], name: 'Dynamic'})
        };
    }

    private static function addChangeConstructor(
        fields:Array<Field>,
        baseContainerTPath:ComplexType,
        normElementCT:ComplexType,
        opName:String,
        pos:Position
    ):Void
    {
        fields.push({
            pos: pos,
            access: [APublic],
            name: 'new',
            kind: FFun({
                args: [
                    { name: 'model', type: baseContainerTPath },
                    { name: 'index', type: TPath({ pack: [], name: 'Int' }) },
                    { name: 'oldValue', type: normElementCT },
                    { name: 'newValue', type: normElementCT }
                ],
                expr: Context.parse(
                    '{'+
                    'super(model, index, oldValue, newValue, $opName);' +
                    '}',
                    pos
                ),
                ret: null
            })
        });
    }

    private static function addChangeRollback(fields:Array<Field>, code:String, pos:Position):Void
    {
        fields.push({
            pos: pos,
            access: [APublic, AOverride],
            name: 'rollback',
            kind: FFun({
                args:[],
                expr: Context.parse(code, pos),
                ret: null
            })
        });
    }

    private static function addChangeToDump(fields:Array<Field>, normElementCT:ComplexType, pos):Void
    {
        var valueDump = '(_newValue == null ? null : _newValue.toDump())';
        if (UtilMacro.tPathIsSimple(normElementCT, pos)) valueDump = '_newValue';

        fields.push({
            pos: pos,
            access: [APublic, AOverride],
            name: 'toDump',
            kind: FFun({
                args: [],
                expr: Context.parse(
                    '{ return { path: _path, newValue: $valueDump, opName: this.opName }; }',
                    pos
                ),
                ret: TPath({pack: ['core', 'actions'], name: 'ActionDump'})
            })
        });
    }

    private static function defineChangeType(
        changeTypeName:String,
        baseContainerTPath:ComplexType,
        normElementCT:ComplexType,
        fields: Array<Field>,
        pos:Position
    ):Void
    {
        Context.defineType({
            pos: pos,
            pack: _pack,
            name: changeTypeName,
            kind: TDClass(
                {
                    pack: ['core', 'actions'],
                    name: 'ChangeBase',
                    params: [
                        TPType(baseContainerTPath),
                        TPType(normElementCT),
                        TPType(TPath({ pack: [], name: 'Int' }))
                    ]
                },
                [],
                false
            ),
            fields: fields
        });
    }
}
#end
