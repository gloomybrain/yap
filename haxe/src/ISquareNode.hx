package ;

interface ISquareNode
{
    var x(default, null):Int;
    var y(default, null):Int;

    var type(default, null):String;

    // never touch those two
    // they are for SquareNet internal usage only
    var next:ISquareNode;
    var prev:ISquareNode;

    // and this one too
    var nextHead:ISquareNode;
}
