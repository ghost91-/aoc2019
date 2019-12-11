module day10.part1.main;

import std;

void main()
{
    auto result = readText("input").maximumDetection;
    result.asteroid.writeln;
    result.lines.length.writeln;
}

alias Asteroid = Tuple!(long, "x", long, "y");

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
                auto diffX = other.x - a.x;
                auto diffY = other.y - a.y;
                auto angle = atan2(diffY.to!double, diffX.to!double);
                auto distance = sqrt((diffX ^^ 2 + diffY ^^ 2).to!double);
                return tuple!("angle", "distance")(angle, distance);
            })
            .array
            .sort!"a.angle < b.angle"
            .array
            .chunkBy!"a.angle == b.angle"
            .array))
        .array
        .maxElement!"a.lines.length";
}

// unittest
// {
//     // given
//     immutable input = `.#..#
// .....
// #####
// ....#
// ...##`;

//     // when
//     immutable result = input.maximumDetection;

//     // then
//     assert(result == 8);
// }

// unittest
// {
//     // given
//     immutable input = `......#.#.
// #..#.#....
// ..#######.
// .#.#.###..
// .#..#.....
// ..#....#.#
// #..#....#.
// .##.#..###
// ##...#..#.
// .#....####`;

//     // when
//     immutable result = input.maximumDetection;

//     // then
//     assert(result == 33);
// }

// unittest
// {
//     // given
//     immutable input = `#.#...#.#.
// .###....#.
// .#....#...
// ##.#.#.#.#
// ....#.#.#.
// .##..###.#
// ..#...##..
// ..##....##
// ......#...
// .####.###.`;

//     // when
//     immutable result = input.maximumDetection;

//     // then
//     assert(result == 35);
// }

// unittest
// {
//     // given
//     immutable input = `.#..#..###
// ####.###.#
// ....###.#.
// ..###.##.#
// ##.##.#.#.
// ....###..#
// ..#.#..#.#
// #..#.#.###
// .##...##.#
// .....#.#..`;

//     // when
//     immutable result = input.maximumDetection;

//     // then
//     assert(result == 41);
// }

// unittest
// {
//     // given
//     immutable input = `.#..##.###...#######
// ##.############..##.
// .#.######.########.#
// .###.#######.####.#.
// #####.##.#.##.###.##
// ..#####..#.#########
// ####################
// #.####....###.#.#.##
// ##.#################
// #####.##.###..####..
// ..######..##.#######
// ####.##.####...##..#
// .#####..#.######.###
// ##...#.##########...
// #.##########.#######
// .####.#.###.###.#.##
// ....##.##.###..#####
// .#.#.###########.###
// #.#.#.#####.####.###
// ###.##.####.##.#..##`;

//     // when
//     immutable result = input.maximumDetection;

//     // then
//     assert(result == 210);
// }
