module day8.part1.main;
import std;

void main()
{
    auto data = File("input", "r").readln
        .strip
        .map!(to!int)
        .map!(it => it - 48);

    auto layerWithFewestZeros = data.toImage(25, 6)
        .minElement!(layer => layer.joiner.filter!(elem => elem == 0).count);

    auto ones = layerWithFewestZeros.joiner.count(1);
    auto twos = layerWithFewestZeros.joiner.count(2);

    writeln(ones * twos);
}

auto toImage(R)(R data, int width, int height)
        if (isInputRange!R && is(ElementType!R : int))
{
    return data.chunks(width).chunks(height);
}

unittest
{
    // given
    auto data = "123456789012".map!(to!int)
        .map!(it => it - 48);

    // when
    auto result = data.toImage(3, 2);

    // then
    assert(result.map!(map!array)
            .map!array
            .array == [[[1, 2, 3], [4, 5, 6]], [[7, 8, 9], [0, 1, 2]]]);
}
