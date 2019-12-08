module day2.part2.main;

import std;

enum Opcode
{
    add = 1,
    multiply = 2,
    halt = 99
}

alias Continue = Flag!"continue";

auto addInstruction(size_t instructionPointer, size_t[] memory)
{
    immutable inAddress1 = memory[instructionPointer + 1];
    immutable inAddress2 = memory[instructionPointer + 2];
    immutable outAddress = memory[instructionPointer + 3];

    return (ref size_t instructionPointer, size_t[] memory) {
        memory[outAddress] = memory[inAddress1] + memory[inAddress2];
        instructionPointer += 4;
        return Continue.yes;
    };
}

auto multiplyInstruction(size_t instructionPointer, size_t[] memory)
{
    immutable inAddress1 = memory[instructionPointer + 1];
    immutable inAddress2 = memory[instructionPointer + 2];
    immutable outAddress = memory[instructionPointer + 3];

    return (ref size_t instructionPointer, size_t[] memory) {
        memory[outAddress] = memory[inAddress1] * memory[inAddress2];
        instructionPointer += 4;
        return Continue.yes;
    };
}

auto haltInstruction()
{
    return delegate(ref size_t instructionPointer, size_t[] memory) => Continue.no;
}

auto nextInstruction(size_t instructionPointer, size_t[] memory)
{
    immutable opcode = memory[instructionPointer];
    switch (opcode)
    {
    case Opcode.add:
        return addInstruction(instructionPointer, memory);
    case Opcode.multiply:
        return multiplyInstruction(instructionPointer, memory);
    case Opcode.halt:
        return haltInstruction();
    default:
        throw new Exception("Invalid opcode %s".format(opcode));
    }
}

void main()
{
    auto memory = File("input", "r").readln.strip.splitter(",").map!(to!size_t).array;

    cartesianProduct(iota(100), iota(100)).each!(((nounAndVerb) {
            auto memoryForProgram = memory.dup;
            immutable noun = nounAndVerb[0];
            immutable verb = nounAndVerb[1];
            memoryForProgram[1] = noun;
            memoryForProgram[2] = verb;
            immutable output = executeProgram(memoryForProgram);
            if (output == 19_690_720)
            {
                writeln("noun: ", noun);
                writeln("verb: ", verb);
                writeln("100 * noun + verb: ", 100 * noun + verb);
                return Flag!"each".no;
            }
            return Flag!"each".yes;
        }));

}

size_t executeProgram(size_t[] memory)
{
    size_t instructionPointer = 0;
    while (true)
    {
        auto instruction = nextInstruction(instructionPointer, memory);
        immutable _continue = instruction(instructionPointer, memory);
        if (_continue == Continue.no)
            break;
    }
    return memory[0];
}
