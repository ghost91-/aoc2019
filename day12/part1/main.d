module day12.part1.main;

import std;

alias Vec3 = Tuple!(int, "x", int, "y", int, "z");
alias Moon = Tuple!(Vec3, "pos", Vec3, "vel");

void main()
{
    auto initialPos = slurp!(int, int, int)("input", "<x=%s, y=%s, z=%s>").map!(to!Vec3);
    auto initialVel = initialPos.map!(it => Vec3(0, 0, 0)).array;
    initialPos.zip(initialVel).map!(to!Moon).array.energyAfterNSteps(1000).writeln;
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
    immutable initialPos = [
        Vec3(-8, -10, 0), Vec3(5, 5, 10), Vec3(2, -7, 3), Vec3(9, -8, -3)
    ];
    immutable initialVel = initialPos.map!(it => Vec3(0, 0, 0)).array;
    auto moons = initialPos.zip(initialVel).map!(to!Moon).array;

    // when
    immutable result = moons.energyAfterNSteps(100);

    // then
    assert(result == 1940);
}
