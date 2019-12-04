import std;

alias Position = Tuple!(int, int);
alias Move = Tuple!(immutable(char), int);

void main()
{
    auto input = File("input", "r");
    auto wire1Data = input.readln.strip;
    auto wire2Data = input.readln.strip;

    auto wire1Positions = wire1Data.positions;
    auto wire2Positions = wire2Data.positions;

    auto intersections = setIntersection(wire1Positions.dup.sort, wire2Positions.dup.sort);

    intersections.filter!(it => it != tuple(0, 0))
        .map!(it => wire1Positions.countUntil(it) + wire2Positions.countUntil(it))
        .fold!min
        .writeln;
}

auto positions(string data)
{
    return data.splitter(',').map!(it => tuple(it[0], it[1 .. $].to!int))
        .fold!((positions, move) => positions.appendMove(move))([tuple(0, 0)]);
}

auto appendMove(Position[] positions, Move move)
{
    return positions ~ positions[$ - 1].newPositionsForMove(move);
}

auto newPositionsForMove(Position lastPosition, Move move)
{
    switch (move[0])
    {
    case 'R':
        return iota(1, move[1] + 1).map!(it => tuple(lastPosition[0] + it, lastPosition[1])).array;
    case 'U':
        return iota(1, move[1] + 1).map!(it => tuple(lastPosition[0], lastPosition[1] + it)).array;
    case 'L':
        return iota(1, move[1] + 1).map!(it => tuple(lastPosition[0] - it, lastPosition[1])).array;
    case 'D':
        return iota(1, move[1] + 1).map!(it => tuple(lastPosition[0], lastPosition[1] - it)).array;
    default:
        throw new Exception("Invalid direction %s".format(move[0]));
    }
}
