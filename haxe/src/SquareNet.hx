package ;

class SquareNet<T:ISquareNode>
{
    private var _squareSize:Int;
    private var _size:Int;
    private var _net:Array<ISquareNode>;

    /**
     * @param squareSize    Длина стороны сектора в условных единицах
     * @param size          Длина стороны сетки в секторах
     **/
    public function new(squareSize:Int, size:Int)
    {
        _squareSize = squareSize;
        _size = size;
        _net = [];

        for (i in 0...(size * size))
        {
            _net[i] = null;
        }
    }

    /**
     * Добавить объект в сетку секторов.
     * Сектор будет выбран автоматически по координатам объекта.
     *
     * @param target    Добавляемый объект
     **/
    public function add(target:T):Void
    {
        var listHead = getSectorHeadForPoint(target.x, target.y);

        if (listHead != null) listHead.prev = target;

        target.next = listHead;

        setSectorHeadForPoint(target.x, target.y, target);
    }

    /**
     * Удалить объект из сетки секторов.
     * Сектор будет выбран автоматически по координатам объекта.
     *
     * ВАЖНО!
     *
     * При перемещении объектов, нужно сначала удалять их из сетки, а потом менять их координаты.
     * Иначе возможны баги с неверным выбором сектора для удаления.
     *
     * @param target    Добавляемый объект
     **/
    public function remove(target:T):Void
    {
        var listHead = getSectorHeadForPoint(target.x, target.y);

        if (listHead == target)
        {
            setSectorHeadForPoint(target.x, target.y, target.next);

            if (target.next != null) target.next.prev = null;
            target.next = null;
        }
        else
        {
            target.prev.next = target.next;
            if (target.next != null) target.next.prev = target.prev;

            target.next = null;
            target.prev = null;
        }
    }

    /**
     * Найти ближайший к заданному объект, подходящий по типу
     *
     * @param target    Объект, от которого начинается поиск
     * @param filter    Функция, принимающая объект и возвращающая true если он нам подходит
     **/
    public function waveSearchFrom(target:T, filter:T -> Bool):T
    {
        var closest:T = null;

        var minDistance = 0;
        var maxDistance = _squareSize;

        while (maxDistance <= _squareSize * _size)
        {
            closest = limitedWaveSearchFrom(target, filter, maxDistance, minDistance);

            if (closest != null) break;

            minDistance = maxDistance;
            maxDistance += _squareSize;
        }

        return closest;
    }

    /**
     * Найти ближайший к заданному объект, подходящий по типу с ограничением по дистанции
     *
     * @param target        Объект, от которого начинается поиск
     * @param filter        Функция, принимающая объект и возвращающая true если он нам подходит
     * @param maxDistance   Максимальная дистанция до объекта
     * @param minDistance   Минимальная дистанция до объекта
     **/
    public function limitedWaveSearchFrom(target:T, filter:T -> Bool, maxDistance:Int, minDistance:Int = 0):T
    {
        var headsHead:ISquareNode = getSectorHeadsAround(target, maxDistance, minDistance);

        var closest:ISquareNode = null;
        var minSquaredDistanceFound:Int = 0;
        var maxSquaredDistance = maxDistance * maxDistance;
        var minSquaredDistance = minDistance * minDistance;

        while (headsHead != null)
        {
            var currentHead = headsHead;

            while (currentHead != null)
            {
                if (currentHead != target && filter(cast currentHead))
                {
                    var dx = target.x - currentHead.x;
                    var dy = target.y - currentHead.y;

                    var squaredDistance = dx * dx + dy * dy;

                    if (maxSquaredDistance >= squaredDistance && minSquaredDistance <= squaredDistance)
                    {
                        if (closest == null || minSquaredDistanceFound > squaredDistance)
                        {
                            closest = currentHead;
                            minSquaredDistanceFound = squaredDistance;
                        }
                    }
                }

                currentHead = currentHead.next;
            }

            headsHead = headsHead.nextHead;
        }

        return cast closest;
    }
    /**
     * Получить 'головы' связных списков с секторами объектов
     * Возвращаются только не пустые списки
     * Списки связаны друг с другом через параметр nextHead
     *
     * @param target        Объект, от которго начинается поиск секторов
     * @param maxDistance   Максимальная дистанция до объекта в секторе
     * @param minDistance   Максимальная дистанция до объекта в секторе
     **/
    public function getSectorHeadsAround(target:T, maxDistance:Int, minDistance:Int):T
    {
        var result:ISquareNode = null;

        var minOutX = getSectorIndexForCoord(target.x - maxDistance);
        var maxOutX = getSectorIndexForCoord(target.x + maxDistance);
        var minInX = getSectorIndexForCoord(target.x - minDistance);
        var maxInX = getSectorIndexForCoord(target.x + minDistance);

        var minOutY = getSectorIndexForCoord(target.y - maxDistance);
        var maxOutY = getSectorIndexForCoord(target.y + maxDistance);
        var minInY = getSectorIndexForCoord(target.y - minDistance);
        var maxInY = getSectorIndexForCoord(target.y + minDistance);

        for (ix in minOutX...maxOutX)
        {
            if (ix < 0 || ix >= _size || ix > minInX || ix < maxInX) continue;

            for (iy in minOutY...maxOutY)
            {
                if (iy < 0 || iy >= _size || iy > minInY || iy < maxInY) continue;

                var sectorListHead = getSectorHead(ix, iy);

                if (sectorListHead == null) continue;

                sectorListHead.nextHead = result;
                result = sectorListHead;
            }
        }

        return cast result;
    }

    private function getSectorHeadForPoint(x:Int, y:Int):ISquareNode
    {
        var ix:Int = getSectorIndexForCoord(x);
        var iy:Int = getSectorIndexForCoord(y);

        return getSectorHead(ix, iy);
    }

    private function setSectorHeadForPoint(x:Int, y:Int, value:ISquareNode):Void
    {
        var ix:Int = getSectorIndexForCoord(x);
        var iy:Int = getSectorIndexForCoord(y);

        setSectorHead(ix, iy, value);
    }

    private inline function getSectorHead(ix:Int, iy:Int):ISquareNode
    {
        return _net[iy * _size + ix];
    }

    private inline function setSectorHead(ix:Int, iy:Int, value:ISquareNode):Void
    {
        _net[iy * _size + ix] = value;
    }

    private inline function getSectorIndexForCoord(coord:Int):Int
    {
        return cast ~~(coord / _squareSize);
    }
}
