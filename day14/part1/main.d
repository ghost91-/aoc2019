module day14.part1.main;

import std;

alias ComponentWithAmount = Tuple!(int, "amount", string, "material");
alias Reaction = Tuple!(int, "amount", string, "output", ComponentWithAmount[], "inputs");

auto toComponentsWithAmounts(string input)
{
    return input.splitter(",").map!strip
        .map!(pipe!(splitter, array))
        .map!(it => ComponentWithAmount(it[0].to!int, it[1]))
        .array;
}

auto toReactionMap(string input)
{
    return input.splitter("\n").map!(line => line.splitter("=>").array)
        .map!(it => tuple(it[1].toComponentsWithAmounts.front, it[0].toComponentsWithAmounts))
        .map!(it => tuple(it[0].material, Reaction(it[0].amount, it[0].material, it[1])))
        .assocArray;
}

void main()
{
    int[string] storedMaterial;
    readText("input").toReactionMap.calculateRequiredOre(1, "FUEL", storedMaterial).writeln;
}

auto calculateRequiredOre(Reaction[string] reactions, int amount, string material,
        int[string] storedMaterial)
{
    if (material == "ORE")
    {
        return amount;
    }

    const reaction = reactions[material];

    immutable requiredAmount = max(0, amount - storedMaterial.require(material, 0));
    storedMaterial[material] = max(0, storedMaterial[material] - amount);

    immutable numberOfReactionsNeeded = requiredAmount / reaction.amount + (
            requiredAmount % reaction.amount != 0);

    immutable requiredOre = reaction.inputs.map!(input => reactions.calculateRequiredOre(
            input.amount * numberOfReactionsNeeded, input.material, storedMaterial)).sum;

    storedMaterial[material] += numberOfReactionsNeeded * reaction.amount - requiredAmount;
    return requiredOre;

}

unittest
{
    // given
    auto reactions = `9 ORE => 2 A
8 ORE => 3 B
7 ORE => 5 C
3 A, 4 B => 1 AB
5 B, 7 C => 1 BC
4 C, 1 A => 1 CA
2 AB, 3 BC, 4 CA => 1 FUEL`.toReactionMap;
    int[string] storedMaterial;

    // when
    immutable result = reactions.calculateRequiredOre(1, "FUEL", storedMaterial);

    // then
    assert(result == 165);
}

unittest
{
    // given
    auto reactions = `157 ORE => 5 NZVS
165 ORE => 6 DCFZ
44 XJWVT, 5 KHKGT, 1 QDVJ, 29 NZVS, 9 GPVTF, 48 HKGWZ => 1 FUEL
12 HKGWZ, 1 GPVTF, 8 PSHF => 9 QDVJ
179 ORE => 7 PSHF
177 ORE => 5 HKGWZ
7 DCFZ, 7 PSHF => 2 XJWVT
165 ORE => 2 GPVTF
3 DCFZ, 7 NZVS, 5 HKGWZ, 10 PSHF => 8 KHKGT`.toReactionMap;
    int[string] storedMaterial;

    // when
    immutable result = reactions.calculateRequiredOre(1, "FUEL", storedMaterial);

    // then
    assert(result == 13_312);
}

unittest
{
    // given
    auto reactions = `2 VPVL, 7 FWMGM, 2 CXFTF, 11 MNCFX => 1 STKFG
17 NVRVD, 3 JNWZP => 8 VPVL
53 STKFG, 6 MNCFX, 46 VJHF, 81 HVMC, 68 CXFTF, 25 GNMV => 1 FUEL
22 VJHF, 37 MNCFX => 5 FWMGM
139 ORE => 4 NVRVD
144 ORE => 7 JNWZP
5 MNCFX, 7 RFSQX, 2 FWMGM, 2 VPVL, 19 CXFTF => 3 HVMC
5 VJHF, 7 MNCFX, 9 VPVL, 37 CXFTF => 6 GNMV
145 ORE => 6 MNCFX
1 NVRVD => 8 CXFTF
1 VJHF, 6 MNCFX => 4 RFSQX
176 ORE => 6 VJHF`.toReactionMap;
    int[string] storedMaterial;

    // when
    immutable result = reactions.calculateRequiredOre(1, "FUEL", storedMaterial);

    // then
    assert(result == 180_697);
}

unittest
{
    // given
    auto reactions = `171 ORE => 8 CNZTR
7 ZLQW, 3 BMBT, 9 XCVML, 26 XMNCP, 1 WPTQ, 2 MZWV, 1 RJRHP => 4 PLWSL
114 ORE => 4 BHXH
14 VRPVC => 6 BMBT
6 BHXH, 18 KTJDG, 12 WPTQ, 7 PLWSL, 31 FHTLT, 37 ZDVW => 1 FUEL
6 WPTQ, 2 BMBT, 8 ZLQW, 18 KTJDG, 1 XMNCP, 6 MZWV, 1 RJRHP => 6 FHTLT
15 XDBXC, 2 LTCX, 1 VRPVC => 6 ZLQW
13 WPTQ, 10 LTCX, 3 RJRHP, 14 XMNCP, 2 MZWV, 1 ZLQW => 1 ZDVW
5 BMBT => 4 WPTQ
189 ORE => 9 KTJDG
1 MZWV, 17 XDBXC, 3 XCVML => 2 XMNCP
12 VRPVC, 27 CNZTR => 2 XDBXC
15 KTJDG, 12 BHXH => 5 XCVML
3 BHXH, 2 VRPVC => 7 MZWV
121 ORE => 7 VRPVC
7 XCVML => 6 RJRHP
5 BHXH, 4 VRPVC => 5 LTCX`.toReactionMap;
    int[string] storedMaterial;

    // when
    immutable result = reactions.calculateRequiredOre(1, "FUEL", storedMaterial);

    // then
    assert(result == 2_210_736);
}
