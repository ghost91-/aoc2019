module day12.part2.main;

import std;

alias Vec3 = Tuple!(int, "x", int, "y", int, "z");
alias Moon = Tuple!(Vec3, "pos", Vec3, "vel");
alias PosVel = Tuple!(int, "pos", int, "vel");

void main()
{
    const initialState = slurp!(int, int, int)("input", "<x=%s, y=%s, z=%s>").map!(to!Vec3)
        .map!(it => Moon(it, Vec3(0, 0, 0)))
        .array;

    initialState.cycleLength.writeln;
}

auto lcm(T)(T a, T b)
{
    if (a == 0 && b == 0)
        return 0;
    return abs(a * b) / gcd(a, b);
}

ulong cycleLength(const Moon[] initialState)
{
    return initialState.map!(it => [
            PosVel(it.pos.x, it.vel.x), PosVel(it.pos.y, it.vel.y),
            PosVel(it.pos.z, it.vel.z)
            ])
        .array
        .transposed
        .map!(it => it.array.cycleLength)
        .fold!lcm;
}

ulong cycleLength(const PosVel[] posvels)
{
    return posvels.recurrence!((a, n) => a[n - 1].nextStep).dropOne.until(posvels).walkLength + 1;
}

auto nextStep(const PosVel[] posvels)
{
    return posvels.updateVel.updatePos;
}

auto updateVel(PosVel)(const PosVel[] posvels)
{
    return posvels.map!(it => posvels.fold!((a, b) => PosVel(a.pos, a.vel + (b.pos - a.pos).sgn))(
            it)).array;
}

auto updatePos(const PosVel[] posvels)
{
    return posvels.map!(it => PosVel(it.pos + it.vel, it.vel)).array;
}

unittest
{
    // given
    const initialState = [
        Vec3(-1, 0, 2), Vec3(2, -10, -7), Vec3(4, -8, 8), Vec3(3, 5, -1),
    ].map!(it => Moon(it, Vec3(0, 0, 0))).array;

    // when
    immutable result = initialState.cycleLength;

    // then
    assert(result == 2772);
}

unittest
{

    // given
    const initialState = [
        Vec3(-8, -10, 0), Vec3(5, 5, 10), Vec3(2, -7, 3), Vec3(9, -8, -3)
    ].map!(it => Moon(it, Vec3(0, 0, 0))).array;

    // when
    immutable result = initialState.cycleLength;

    // then
    assert(result == 4_686_774_924);
}
