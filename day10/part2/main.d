module day10.part1.main;

import std;

void main()
{
    readText("input").maximumDetection.lines.drop(199)
        .map!(it => it[0].asteroid.x * 100 + it[0].asteroid.y).front.writeln;
}

alias Asteroid = Tuple!(long, "x", long, "y");

auto mod2PI(double n)
{
    if (0 <= n && n < 2 * PI)
        return n;
    else if (n < 0)
        return mod2PI(n + 2 * PI);
    else
        return mod2PI(n - 2 * PI);

}

auto angleBetween(double x1, double y1, double x2, double y2)
{
    return atan2((x2 - x1).to!double, -(y2 - y1)).mod2PI;
}

auto distanceBetween(double x1, double y1, double x2, double y2)
{
    return sqrt((x2 - x1) ^^ 2 + (y2 - y1) ^^ 2);
}

auto maximumDetection(string input)
{
    auto asteroids = input.splitter("\n").array
        .map!(row => row.enumerate.filter!(it => it.value == '#'))
        .enumerate
        .map!(row => row.value.map!(it => Asteroid(it.index.to!long, row.index.to!long)))
        .joiner
        .array;

    return asteroids.map!((a) => tuple!("asteroid", "lines")(a, asteroids.filter!(b => b != a)
            .map!((other) {
                auto angle = angleBetween(a.x, a.y, other.x, other.y);
                auto distance = distanceBetween(a.x, a.y, other.x, other.y);
                return tuple!("angle", "distance", "asteroid")(angle, distance, other);
            })
            .array
            .sort!"a.angle < b.angle"
            .array
            .chunkBy!"a.angle == b.angle"
            .map!(it => it.array)
            .array))
        .maxElement!"a.lines.length";
}

unittest
{
    // given
    immutable input = `.#..#
.....
#####
....#
...##`;

    // when
    immutable result = input.maximumDetection.lines.length;

    // then
    assert(result == 8);
}

unittest
{
    // given
    immutable input = `......#.#.
#..#.#....
..#######.
.#.#.###..
.#..#.....
..#....#.#
#..#....#.
.##.#..###
##...#..#.
.#....####`;

    // when
    immutable result = input.maximumDetection.lines.length;

    // then
    assert(result == 33);
}

unittest
{
    // given
    immutable input = `#.#...#.#.
.###....#.
.#....#...
##.#.#.#.#
....#.#.#.
.##..###.#
..#...##..
..##....##
......#...
.####.###.`;

    // when
    immutable result = input.maximumDetection.lines.length;

    // then
    assert(result == 35);
}

unittest
{
    // given
    immutable input = `.#..#..###
####.###.#
....###.#.
..###.##.#
##.##.#.#.
....###..#
..#.#..#.#
#..#.#.###
.##...##.#
.....#.#..`;

    // when
    immutable result = input.maximumDetection.lines.length;

    // then
    assert(result == 41);
}

unittest
{
    // given
    immutable input = `.#..##.###...#######
##.############..##.
.#.######.########.#
.###.#######.####.#.
#####.##.#.##.###.##
..#####..#.#########
####################
#.####....###.#.#.##
##.#################
#####.##.###..####..
..######..##.#######
####.##.####...##..#
.#####..#.######.###
##...#.##########...
#.##########.#######
.####.#.###.###.#.##
....##.##.###..#####
.#.#.###########.###
#.#.#.#####.####.###
###.##.####.##.#..##`;

    // when
    immutable result = input.maximumDetection.lines.length;

    // then
    assert(result == 210);
}
