module day10.part2.main;

import std;

void main()
{
    auto _200th = readText("input").nthDestroyed(200);
    writeln(_200th.asteroid.x * 100 + _200th.asteroid.y);
}

alias Asteroid = Tuple!(long, "x", long, "y");

struct Angle
{
    long x;
    long y;

    long opCmp(const Angle other) const
    {
        auto selfInLeftHalf = this.x < 0;
        auto otherInLeftHalf = other.x < 0;
        if (selfInLeftHalf != otherInLeftHalf)
            return selfInLeftHalf - otherInLeftHalf;
        if (this.x == 0 && other.x == 0)
            return this.y.sgn - other.y.sgn;
        return other.cross(this).sgn;
    }

    auto cross(const Angle other) const
    {
        return this.x * other.y - this.y * other.x;
    }
}

auto nthDestroyed(string input, size_t n)
in(n > 0)
{
    return input.maximumDetection.lines.transposed.joiner.drop(n - 1).front;
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
    immutable result = input.nthDestroyed(200);

    // then
    assert(result.asteroid == Asteroid(8, 2));
}

auto maximumDetection(string input)
{
    auto asteroids = input.splitter("\n").array
        .map!(row => row.enumerate.filter!(it => it.value == '#'))
        .enumerate
        .map!(row => row.value.map!(it => Asteroid(it.index.to!long, row.index.to!long)))
        .joiner
        .array;

    return asteroids.map!((station) => tuple!("asteroid", "lines")(station,
            asteroids.filter!(other => other != station)
            .map!((other) {
                auto diffX = other.x - station.x;
                auto diffY = other.y - station.y;
                auto denom = gcd(diffX.abs, diffY.abs);
                auto angle = Angle(diffX / denom, diffY / denom);
                return tuple!("angle", "denom", "asteroid")(angle, denom, other);
            })
            .array
            .sort!"a.angle < b.angle"
            .chunkBy!"a.angle == b.angle"
            .map!(a => a.array.sort!"a.denom < b.denom")
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
