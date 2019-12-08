module day8.part2.main;

import std;

void main()
{
    enum width = 25;
    enum height = 6;

    auto data = File("input", "r").readln
        .strip
        .map!(to!int)
        .map!(it => it - 48)
        .array;

    data.toImage(width, height).reduceLayers.map!(it => it == 0 ? ' ' : '▮')
        .chunks(width).each!writeln;
}

auto toImage(R)(R data, int width, int height)
        if (isInputRange!R && is(ElementType!R : int))
{
    return data.chunks(width * height).array;
}

unittest
{
    // given
    auto data = "123456789012".map!(to!int)
        .map!(it => it - 48)
        .array;

    // when
    auto result = data.toImage(3, 2);

    // then
    assert(result == [[1, 2, 3, 4, 5, 6], [7, 8, 9, 0, 1, 2]]);
}

auto combineLayers(int[] layer1, int[] layer2)
{
    return layer1.zip(layer2).map!(pixels => pixels[0] == 2 ? pixels[1] : pixels[0]).array;
}

auto reduceLayers(int[][] image)
{
    return image.fold!(combineLayers);
}

unittest
{
    // given
    auto data = "0222112222120000".map!(to!int)
        .map!(it => it - 48)
        .array;

    // when
    auto result = data.toImage(2, 2).reduceLayers;

    // then
    assert(result == [0, 1, 1, 0]);
}
