package core.macro;

#if macro

import haxe.macro.Context;
import haxe.macro.TypeTools;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.ComplexTypeTools;

using haxe.macro.Tools;
using haxe.macro.ComplexTypeTools;

class ValueMapMacro
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
            case TInst(_.get() => { pack: _pack, name: 'ValueMapImpl' }, [elementType]):
                var result = genSubTypeFor(elementType, pos);
                performing = false;
                return result;

            default:
                Context.fatalError('ValueMapMacro.build() can be called only on ValueMapImpl!', pos);
        }

        // this will never happen
        return localType;
    }

    private static function genSubTypeFor(elementType:Type, pos:Position):Type
    {
        var elementCT = elementType.toComplexType();
        var normElementCT = UtilMacro.normalizeTPath(elementCT, pos);
        var elementTypeName = UtilMacro.getFullComplexTypeName(normElementCT, pos);
        var typeName = 'ValueMap_of_' + elementTypeName.split('.').join('_');
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

        var fields:Array<Field> = [
            {
                pos: pos,
                access: [APrivate, AOverride],
                name: 'setRooted',
                kind: FFun(genMapSetRootedFun(normElementCT, pos))
            },
            {
                pos: pos,
                access: [APublic, AOverride],
                name: 'set',
                kind: FFun(genMapSetFun(elementCT, normElementCT, pos))
            },
            {
                pos: pos,
                access: [APrivate, AOverride],
                name: 'insert',
                kind: FFun(genMapInsertFun(elementCT, normElementCT, pos))
            },
            {
                pos: pos,
                access: [APublic, AOverride],
                name: 'remove',
                kind: FFun(genMapRemoveFun(elementCT, normElementCT, pos))
            },
            {
                pos: pos,
                access: [APublic, AOverride],
                name: 'fromDump',
                kind: FFun(genMapFromDumpFun(normElementCT, pos))
            },
            {
                pos: pos,
                access: [APublic, AOverride],
                name: 'toDump',
                kind: FFun(genMapToDumpFun(normElementCT, pos))
            }
        ];

        Context.defineType({
            pos: pos,
            pack: _pack,
            name: typeName,
            kind: TDClass({ pack: _pack, name: 'ValueMapBase', params: [TPType(elementCT)] }, [], false),
            fields: fields
        });

        return Context.getType(fullTypeName);
    }

    private static function genMapSetRootedFun(normElementCT:ComplexType, pos:Position):Function
    {
        var code = '';

        code += '{';

        code += 'if (this.__isRooted == value) return;';
        code += 'this.__isRooted = value;';

        if (!UtilMacro.tPathIsSimple(normElementCT, pos))
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

    private static function genMapSetFun(elementCT:ComplexType, normElementCT:ComplexType, pos:Position):Function
    {
        var changeClsName = genIndexChangeType(elementCT, pos);

        var code = '';

        code += '{';

        code += 'this.assertWriteEnabled();';

        code += 'if (!_data.exists(key))';
        code += '{';
        code += 'this.insert(key, value);';
        code += 'return;';
        code += '}';

        code += 'if (${UtilMacro.genComparsionCode('_data[key]', 'value', normElementCT, pos)}) return;';

        code += 'var oldValue = _data[key];';
        code += '_data[key] = value;';

        if (!UtilMacro.tPathIsSimple(normElementCT, pos))
        {
            code += 'this.removeParent(oldValue);';
            code += 'if (oldValue != null) oldValue.setRooted(false);';

            code += 'this.addParent(value, key);';
            code += 'if (value != null) value.setRooted(this.__isRooted);';
        }

        code += UtilMacro.genUpdateHashCode(normElementCT, 'oldValue', 'value', pos);

        code += 'if ($ACTION_LOG._loggingEnabled && this.__isRooted) {';
        code += 'var change = new $changeClsName(this, key, oldValue, value);';
        code += '$ACTION_LOG._actions.push(change);';
        code += '}';

        code += '}';

        return {
            args: [
                {
                    name: 'key',
                    type: TPath({pack: [], name: 'String'})
                },
                {
                    name: 'value',
                    type: normElementCT
                }
            ],
            expr: Context.parse(code, pos),
            ret: null
        };
    }

    private static function genMapInsertFun(elementCT:ComplexType, normElementCT:ComplexType, pos:Position):Function
    {
        var changeClsName = genInsertChangeType(elementCT, pos);
        var defaultValue = UtilMacro.genDefaultValue(elementCT, pos);

        var code = '';

        code += '{';

        code += '_data[key] = value;';

        if (!UtilMacro.tPathIsSimple(normElementCT, pos))
        {
            code += 'this.addParent(value, key);';
            code += 'if (value != null) value.setRooted(this.__isRooted);';
        }

        code += UtilMacro.genUpdateHashCode(normElementCT, defaultValue, 'value', pos);

        code += 'if ($ACTION_LOG._loggingEnabled && this.__isRooted) {';
        code += 'var change = new $changeClsName(this, key, $defaultValue, value);';
        code += '$ACTION_LOG._actions.push(change);';
        code += '}';

        code += '}';

        return {
            args: [
                {
                    name: 'key',
                    type: TPath({pack: [], name: 'String'})
                },
                {
                    name: 'value',
                    type: normElementCT
                }
            ],
            expr: Context.parse(code, pos),
            ret: null
        };
    }

    private static function genMapRemoveFun(elementCT:ComplexType, normElementCT:ComplexType, pos:Position):Function
    {
        var changeClsName = genRemoveChangeType(elementCT, pos);
        var defaultValue = UtilMacro.genDefaultValue(elementCT, pos);

        var code = '';

        code += '{';

        code += 'this.assertWriteEnabled();';
        code += 'if (!_data.exists(key)) throw new Error("Key " + key + " does not exist!");';

        code += 'var oldValue = _data[key];';
        code += '_data.remove(key);';

        if (!UtilMacro.tPathIsSimple(normElementCT, pos))
        {
            code += 'this.removeParent(oldValue);';
            code += 'if (oldValue != null) oldValue.setRooted(false);';
        }

        code += UtilMacro.genUpdateHashCode(normElementCT, 'oldValue', defaultValue, pos);

        code += 'if ($ACTION_LOG._loggingEnabled && this.__isRooted) {';
        code += 'var change = new $changeClsName(this, key, oldValue, $defaultValue);';
        code += '$ACTION_LOG._actions.push(change);';
        code += '}';

        code += '}';

        return {
            args: [
                {
                    name: 'key',
                    type: TPath({pack: [], name: 'String'})
                }
            ],
            expr: Context.parse(code, pos),
            ret: null
        };
    }

    private static function genMapFromDumpFun(normElementCT:ComplexType, pos:Position):Function
    {
        var code = '';

        code += '{';

        code += 'this.reset();';

        code += 'var orderedKeys = Reflect.fields(dump);';
        code += 'orderedKeys.sort(Reflect.compare);';

        code += 'for(key in orderedKeys)';
        code += '{';

        if (UtilMacro.tPathIsSimple(normElementCT, pos))
        {
            if (Context.defined('js') || Context.defined('flash'))
            {
                code += 'var value = untyped dump[key];';
            }
            else
            {
                code += 'var value = Reflect.field(dump, key);';
            }
        }
        else
        {
            if (Context.defined('js') || Context.defined('flash'))
            {
                code += 'var v = untyped dump[key];';
            }
            else
            {
                code += 'var v = Reflect.field(dump, key);';
            }

            code += 'var value = null;';

            code += 'if (v != null)';
            code += '{';
            code += 'value = new ${UtilMacro.getFullComplexTypeName(normElementCT, pos)}();';
            code += 'value.fromDump(v);';
            code += '}';
        }

        code += 'this.set(key, value);';

        code += '}'; // for

        code += '}';

        return {
            args: [{ name: 'dump', type: TPath({pack: [], name: 'Dynamic'}) }],
            expr: Context.parse(code, pos),
            ret: null
        };
    }

    private static function genMapToDumpFun(normElementCT:ComplexType, pos:Position):Function
    {
        var code = '';

        code += '{';

        code += 'var result:Dynamic = {};';

        code += 'for(key in _data.keys())';
        code += '{';
        if (UtilMacro.tPathIsSimple(normElementCT, pos))
        {
            if (Context.defined('js') || Context.defined('flash'))
            {
                code += 'untyped result[key] = _data[key];';
            }
            else
            {
                code += 'Reflect.setField(result, key, _data[key]);';
            }
        }
        else
        {
            code += 'var v = _data[key];';
            code += 'var value = (v == null ? null : v.toDump());';
            code += 'Reflect.setField(result, key, value);';
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

    private static function genIndexChangeType(elementCT:ComplexType, pos:Position):String
    {
        var normElementCT = UtilMacro.normalizeTPath(elementCT, pos);
        var elementTypeName = UtilMacro.getFullComplexTypeName(elementCT, pos);
        var containerTypeName = 'ValueMap_of_' + elementTypeName.split('.').join('_');
        var changeTypeName = 'IndexChange$containerTypeName';

        var baseContainerTPath = TPath({ pack: _pack, name: 'ValueMapBase', params: [TPType(elementCT)] });

        var fields:Array<Field> = [
            {
                pos: pos,
                access: [APublic],
                name: 'new',
                kind: FFun({
                    args: [
                        { name: 'model', type: baseContainerTPath },
                        { name: 'key', type: TPath({ pack: [], name: 'String' }) },
                        { name: 'oldValue', type: normElementCT },
                        { name: 'newValue', type: normElementCT }
                    ],
                    expr: Context.parse(
                        '{'+
                        'super(model, key, oldValue, newValue, $CHANGE_OP.INDEX);' +
                        '}',
                        pos
                    ),
                    ret: null
                })
            },
            {
                pos: pos,
                access: [APublic, AOverride],
                name: 'rollback',
                kind: FFun({
                    args:[],
                    expr: Context.parse('{ _model.set(_key, _oldValue); }', pos),
                    ret: null
                })
            }
        ];

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
                        TPType(TPath({ pack: [], name: 'String' }))
                    ]
                },
                [],
                false
            ),
            fields: fields
        });

        return '${_pack.join(".")}.$changeTypeName';
    }

    private static function genInsertChangeType(elementCT:ComplexType, pos:Position):String
    {
        var normElementCT = UtilMacro.normalizeTPath(elementCT, pos);
        var elementTypeName = UtilMacro.getFullComplexTypeName(elementCT, pos);
        var containerTypeName = 'ValueMap_of_' + elementTypeName.split('.').join('_');
        var changeTypeName = 'InsertChange$containerTypeName';

        var baseContainerTPath = TPath({ pack: _pack, name: 'ValueMapBase', params: [TPType(elementCT)] });

        var fields:Array<Field> = [
            {
                pos: pos,
                access: [APublic],
                name: 'new',
                kind: FFun({
                    args: [
                        { name: 'model', type: baseContainerTPath },
                        { name: 'key', type: TPath({ pack: [], name: 'String' }) },
                        { name: 'oldValue', type: normElementCT },
                        { name: 'newValue', type: normElementCT }
                    ],
                    expr: Context.parse(
                        '{'+
                        'super(model, key, oldValue, newValue, $CHANGE_OP.INSERT);' +
                        '}',
                        pos
                    ),
                    ret: null
                })
            },
            {
                pos: pos,
                access: [APublic, AOverride],
                name: 'rollback',
                kind: FFun({
                    args:[],
                    expr: Context.parse('{ _model.remove(_key); }', pos),
                    ret: null
                })
            }
        ];

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
                        TPType(TPath({ pack: [], name: 'String' }))
                    ]
                },
                [],
                false
            ),
            fields: fields
        });

        return '${_pack.join(".")}.$changeTypeName';
    }

    private static function genRemoveChangeType(elementCT:ComplexType, pos:Position):String
    {
        var normElementCT = UtilMacro.normalizeTPath(elementCT, pos);
        var elementTypeName = UtilMacro.getFullComplexTypeName(elementCT, pos);
        var containerTypeName = 'ValueMap_of_' + elementTypeName.split('.').join('_');
        var changeTypeName = 'RemoveChange$containerTypeName';

        var baseContainerTPath = TPath({ pack: _pack, name: 'ValueMapBase', params: [TPType(elementCT)] });

        var fields:Array<Field> = [
            {
                pos: pos,
                access: [APublic],
                name: 'new',
                kind: FFun({
                    args: [
                        { name: 'model', type: baseContainerTPath },
                        { name: 'key', type: TPath({ pack: [], name: 'String' }) },
                        { name: 'oldValue', type: normElementCT },
                        { name: 'newValue', type: normElementCT }
                    ],
                    expr: Context.parse(
                        '{'+
                        'super(model, key, oldValue, newValue, $CHANGE_OP.REMOVE);' +
                        '}',
                        pos
                    ),
                    ret: null
                })
            },
            {
                pos: pos,
                access: [APublic, AOverride],
                name: 'rollback',
                kind: FFun({
                    args:[],
                    expr: Context.parse('{ _model.set(_key, _oldValue); }', pos),
                    ret: null
                })
            }
        ];

        fields.push({
            pos: pos,
            access: [APublic, AOverride],
            name: 'toDump',
            kind: FFun({
                args: [],
                expr: Context.parse(
                    '{ return { path: _path, newValue: null, opName: this.opName }; }',
                    pos
                ),
                ret: TPath({pack: ['core', 'actions'], name: 'ActionDump'})
            })
        });

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
                        TPType(TPath({ pack: [], name: 'String' }))
                    ]
                },
                [],
                false
            ),
            fields: fields
        });

        return '${_pack.join(".")}.$changeTypeName';
    }

}
#end
