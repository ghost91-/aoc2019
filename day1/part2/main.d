module day1.part2.main;

import std;

int calculateRequiredFuel(int mass)
{
    return calculateTotalMass(mass) - mass;
}

int calculateTotalMass(int mass)
{
    immutable requiredFuel = mass / 3 - 2;
    return requiredFuel <= 0 ? mass : mass + calculateTotalMass(requiredFuel);
}

void main()
{
    File("input", "r").byLine
        .map!(to!int)
        .map!(calculateRequiredFuel)
        .sum
        .writeln;
}
