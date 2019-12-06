module day6.part1.main;

import std;

alias Pair = Tuple!(string, "key", string, "value");
alias pair = tuple!("key", "value");

void main()
{
    auto directOrbits = File("input", "r").byLine
        .map!(str => str.split(")"))
        .map!(pair => tuple(pair[1].to!string, pair[0].to!string))
        .assocArray;

    int[string] orbitLengths;

    directOrbits.byPair.fold!((lengths, kv) => calculateOrbitLengths(kv,
            lengths, directOrbits)[1])(orbitLengths).values.sum.writeln;
}

Tuple!(int, int[string]) calculateOrbitLengths(Pair kv, int[string] orbitLengths,
        string[string] directOrbits)
{
    if (kv.key == "COM")
    {
        orbitLengths[kv.key] = 0;
    }
    else if (kv.value == "COM")
    {
        orbitLengths[kv.key] = 1;
    }
    else
    {
        orbitLengths[kv.key] = 1 + orbitLengths.require(kv.value, calculateOrbitLengths(pair(kv.value,
                directOrbits[kv.value]), orbitLengths, directOrbits)[0]);
    }
    return tuple(orbitLengths[kv.key], orbitLengths);
}
