module day12.part1.main;

import std;

alias Vec3 = Tuple!(int, "x", int, "y", int, "z");
alias Moon = Tuple!(Vec3, "pos", Vec3, "vel");

void main()
{
    const initialState = slurp!(int, int, int)("input", "<x=%s, y=%s, z=%s>").map!(to!Vec3)
        .map!(it => Moon(it, Vec3(0, 0, 0)))
        .array;

    initialState.energyAfterNSteps(1000).writeln;
}

auto energyAfterNSteps(const Moon[] moons, size_t n)
{
    return iota(n).fold!((moons, i) => moons.nextStep)(moons).energy;
}

auto energy(const Moon[] moons)
{
    return moons.map!(it => (it.pos.x.abs + it.pos.y.abs + it.pos.z.abs) * (
            it.vel.x.abs + it.vel.y.abs + it.vel.z.abs)).sum;
}

auto nextStep(const Moon[] moons)
{
    return moons.updateVel.updatePos;
}

unittest
{
    // given
    immutable inititalState = [
        Moon(Vec3(-1, 0, 2), Vec3(0, 0, 0)),
        Moon(Vec3(2, -10, -7), Vec3(0, 0, 0)),
        Moon(Vec3(4, -8, 8), Vec3(0, 0, 0)), Moon(Vec3(3, 5, -1), Vec3(0, 0, 0)),
    ];

    // when
    immutable result = inititalState.nextStep;

    // then
    immutable expected = [
        Moon(Vec3(2, -1, 1), Vec3(3, -1, -1)),
        Moon(Vec3(3, -7, -4), Vec3(1, 3, 3)),
        Moon(Vec3(1, -7, 5), Vec3(-3, 1, -3)),
        Moon(Vec3(2, 2, 0), Vec3(-1, -3, 1)),
    ];

    assert(result == expected);
}

auto updateVel(const Moon[] moons)
{
    return moons.map!(it => moons.fold!((a, b) => Moon(a.pos,
            Vec3(a.vel.x + (b.pos.x - a.pos.x).sgn, a.vel.y + (b.pos.y - a.pos.y)
            .sgn, a.vel.z + (b.pos.z - a.pos.z).sgn)))(it)).array;
}

auto updatePos(const Moon[] moons)
{
    return moons.map!(it => Moon(Vec3(it.pos.x + it.vel.x, it.pos.y + it.vel.y, it.pos.z + it.vel.z),
            it.vel)).array;
}

unittest
{
    // given
    const initialState = [
        Vec3(-8, -10, 0), Vec3(5, 5, 10), Vec3(2, -7, 3), Vec3(9, -8, -3)
    ].map!(it => Moon(it, Vec3(0, 0, 0))).array;

    // when
    immutable result = initialState.energyAfterNSteps(100);

    // then
    assert(result == 1940);
}
