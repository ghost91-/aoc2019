module day1.part1.main;

import std;

auto calculateRequiredFuel(T)(T mass) if (isIntegral!T)
{
    return mass / 3 - 2;
}

void main()
{
    File("input", "r").byLine
        .map!(to!ulong)
        .map!(calculateRequiredFuel)
        .sum
        .writeln;
}
