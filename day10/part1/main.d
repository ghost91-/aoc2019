module day10.part1.main;

import std;

void main()
{
    readText("input").maximumDetection.writeln;
}

alias Asteroid = Tuple!(long, "x", long, "y");
alias asteroid = tuple!("x", "y");

auto maximumDetection(string input)
{
    auto asteroids = input.splitter("\n").array
        .retro
        .map!(row => row.enumerate.filter!(it => it.value == '#'))
        .enumerate
        .map!(row => row.value.map!(it => asteroid(it.index.to!long, row.index.to!long)))
        .joiner
        .array;

    return asteroids.map!((a) {
        return asteroids.filter!(b => b != a)
            .fold!((canSee, other) {
                immutable diffX = other.x - a.x;
                immutable diffY = other.y - a.y;
                immutable denom = gcd(abs(diffX), abs(diffY));
                immutable unitX = diffX / denom;
                immutable unitY = diffY / denom;
                auto firstInLineOfSight = iota(1, denom + 1).map!(i => asteroid(a.x + i * unitX,
                a.y + i * unitY))
                .find!(it => asteroids.canFind(it))
                .front;
                return firstInLineOfSight == other ? canSee + 1 : canSee;
            })(0);
    }).maxElement;
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
    immutable result = input.maximumDetection;

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
    immutable result = input.maximumDetection;

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
    immutable result = input.maximumDetection;

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
    immutable result = input.maximumDetection;

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
    immutable result = input.maximumDetection;

    // then
    assert(result == 210);
}
