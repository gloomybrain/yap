package ;

import core.models.collections.ValueArray;
import data.InnerModel;
import core.BaseContext;
import core.queries.BaseQuery;
import core.commands.BaseCommand;
import data.Dump;

@:expose('Context')
class Context extends BaseContext<Dump>
{
    public static function main() {}

    override private function init()
    {
        this.executor.addExternal('incrementInteger', IncrementIntegerCommand);
        this.queries.addExternal('getInteger', GetIntegerQuery);

        this.executor.addExternal('pushBareArray', PushBareArrayCommand);
        this.executor.addExternal('popBareArray', PopBareArrayCommand);
        this.queries.addExternal('getBareArrayLength', GetBareArrayLengthQuery);

        this.executor.addExternal('setNothingToNull', SetNothingToNullCommand);
        this.executor.addExternal('setNothingToValue', SetNothingToValueCommand);
        this.executor.addExternal('shuffleArray', ShuffleArrayCommand);
    }
}

class IncrementIntegerCommand extends BaseCommand<Dump>
{
    override public function execute(?args:Dynamic):Void
    {
        this.model.integer += 1;
    }
}

class GetIntegerQuery extends BaseQuery<Dump>
{
    override public function run(?params:Dynamic):Dynamic
    {
        return this.model.integer;
    }
}

class PushBareArrayCommand extends BaseCommand<Dump>
{
    override public function execute(?args:Dynamic):Void
    {
        this.model.bare_array.push(this.model.bare_array.length);
    }
}

class PopBareArrayCommand extends BaseCommand<Dump>
{
    override public function execute(?args:Dynamic):Void
    {
        this.model.bare_array.pop();
    }
}

class GetBareArrayLengthQuery extends BaseQuery<Dump>
{
    override public function run(?params:Dynamic):Dynamic
    {
        return this.model.bare_array.length;
    }
}

class SetNothingToNullCommand extends BaseCommand<Dump>
{
    override public function execute(?params:Dynamic):Void
    {
        this.model.nothing = null;
    }
}

class SetNothingToValueCommand extends BaseCommand<Dump>
{
    override public function execute(?params:Dynamic):Void
    {
        this.model.nothing = new InnerModel();
    }
}

class ShuffleArrayCommand extends BaseCommand<Dump>
{
    override public function execute(?params:Dynamic):Void
    {
        var array:ValueArray<Int> = model.bare_array;
        var len:Int = array.length;
        var seed:Float = 123.321;
        var nextSeed:Float = 0;

        for(i in 0...len)
        {
            var rnd = Utils.random(seed);
            seed = rnd.nextSeed;

            var element:Int = array.shift();
            var index:Int = Math.round(rnd.result * array.length);

            array.insert(element, index);
        }
    }
}
