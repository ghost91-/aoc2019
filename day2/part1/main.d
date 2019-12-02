module day2.part1.main;

import std;

enum Opcodes : uint
{
    add = 1,
    mult = 2,
    abbort = 99
}

void main()
{
    auto operations = File("input", "r").readln.strip.splitter(",").map!(to!uint).array;

    size_t index = 0;

    operations[1] = 12;
    operations[2] = 2;

    while (true)
    {
        // writeln(index / 4, ": ", operations);
        immutable opcode = operations[index];
        if (opcode == Opcodes.abbort)
            break;
        if (opcode != Opcodes.add && opcode != Opcodes.mult)
        {
            stderr.writefln("Error, invalid opcode %s.", opcode);
            break;
        }
        size_t input1Address = operations[index + 1];
        size_t input2Address = operations[index + 2];
        size_t outputAddress = operations[index + 3];
        if (opcode == Opcodes.add)
            operations[outputAddress] = operations[input1Address] + operations[input2Address];
        else
            operations[outputAddress] = operations[input1Address] * operations[input2Address];

        index += 4;
    }
    operations[0].writeln;
}
