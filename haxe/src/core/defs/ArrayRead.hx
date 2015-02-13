package core.defs;

/**
* Массив, доступный только для чтения.
**/
abstract ArrayRead<T>(Array<T>) from Array<T>
{
    @:arrayAccess inline function get( i:Int ):T return this[i];

    public var length(get, never):Int;

    inline function get_length( ) return this.length;
}
