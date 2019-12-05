module day5.part2.main;

import std;

enum Opcode
{
    add = 1,
    multiply = 2,
    input = 3,
    output = 4,
    jumpIfTrue = 5,
    jumpIfFalse = 6,
    lessThan = 7,
    equals = 8,
    halt = 99
}

enum ParameterMode
{
    position = 0,
    immediate = 1
}

struct Parameter
{
    int value;
    ParameterMode mode;

    ref int derefIfNeeded(int[] memory)
    {
        if (mode == ParameterMode.immediate)
            return value;
        else
            return memory[value];
    }
}

alias Continue = Flag!"continue";

auto parameterMode(int value, size_t parameterIndex)
{
    immutable factor = 100 * 10 ^^ parameterIndex;
    immutable parameterMode = (value / factor) % 10;
    static foreach (member; EnumMembers!ParameterMode)
    {
        if (member == parameterMode)
            return member;
    }
    throw new Exception("Invalid parameter mode %s".format(parameterMode));
}

auto parameter(const size_t instructionPointer, const int[] memory, const size_t parameterIndex)
{
    auto mode = parameterMode(memory[instructionPointer], parameterIndex);
    return Parameter(memory[instructionPointer + 1 + parameterIndex], mode);
}

auto addInstruction(size_t instructionPointer, int[] memory)
{
    auto value1 = parameter(instructionPointer, memory, 0);
    auto value2 = parameter(instructionPointer, memory, 1);
    auto outAddress = parameter(instructionPointer, memory, 2);

    return (ref size_t instructionPointer, int[] memory) {
        outAddress.derefIfNeeded(memory) = value1.derefIfNeeded(
                memory) + value2.derefIfNeeded(memory);
        instructionPointer += 4;
        return Continue.yes;
    };
}

auto multiplyInstruction(size_t instructionPointer, int[] memory)
{
    auto value1 = parameter(instructionPointer, memory, 0);
    auto value2 = parameter(instructionPointer, memory, 1);
    auto outAddress = parameter(instructionPointer, memory, 2);

    return (ref size_t instructionPointer, int[] memory) {
        outAddress.derefIfNeeded(memory) = value1.derefIfNeeded(
                memory) * value2.derefIfNeeded(memory);
        instructionPointer += 4;
        return Continue.yes;
    };
}

auto inputInstruction(size_t instructionPointer, int[] memory)
{
    auto outAddress = parameter(instructionPointer, memory, 0);

    return (ref size_t instructionPointer, int[] memory) {
        scanf(" %d", &outAddress.derefIfNeeded(memory));
        instructionPointer += 2;
        return Continue.yes;
    };
}

auto outputInstruction(size_t instructionPointer, int[] memory)
{
    auto value = parameter(instructionPointer, memory, 0);

    return (ref size_t instructionPointer, int[] memory) {
        value.derefIfNeeded(memory).writeln;
        instructionPointer += 2;
        return Continue.yes;
    };
}

auto jumpIfTrueInstruction(size_t instructionPointer, int[] memory)
{
    auto toBeChecked = parameter(instructionPointer, memory, 0);
    auto target = parameter(instructionPointer, memory, 1);

    return (ref size_t instructionPointer, int[] memory) {
        if (toBeChecked.derefIfNeeded(memory) != 0)
            instructionPointer = target.derefIfNeeded(memory).to!size_t;
        else
            instructionPointer += 3;
        return Continue.yes;
    };
}

auto jumpIfFalseInstruction(size_t instructionPointer, int[] memory)
{
    auto toBeChecked = parameter(instructionPointer, memory, 0);
    auto target = parameter(instructionPointer, memory, 1);

    return (ref size_t instructionPointer, int[] memory) {
        if (toBeChecked.derefIfNeeded(memory) == 0)
            instructionPointer = target.derefIfNeeded(memory).to!size_t;
        else
            instructionPointer += 3;
        return Continue.yes;
    };
}

auto lessThanInstruction(size_t instructionPointer, int[] memory)
{
    auto value1 = parameter(instructionPointer, memory, 0);
    auto value2 = parameter(instructionPointer, memory, 1);
    auto outAddress = parameter(instructionPointer, memory, 2);

    return (ref size_t instructionPointer, int[] memory) {
        outAddress.derefIfNeeded(memory) = value1.derefIfNeeded(
                memory) < value2.derefIfNeeded(memory) ? 1 : 0;
        instructionPointer += 4;
        return Continue.yes;
    };
}

auto equalsInstruction(size_t instructionPointer, int[] memory)
{
    auto value1 = parameter(instructionPointer, memory, 0);
    auto value2 = parameter(instructionPointer, memory, 1);
    auto outAddress = parameter(instructionPointer, memory, 2);

    return (ref size_t instructionPointer, int[] memory) {
        outAddress.derefIfNeeded(memory) = value1.derefIfNeeded(
                memory) == value2.derefIfNeeded(memory) ? 1 : 0;
        instructionPointer += 4;
        return Continue.yes;
    };
}

auto haltInstruction(size_t instructionPointer, int[] memory)
{
    return delegate(ref size_t instructionPointer, int[] memory) => Continue.no;
}

auto nextInstruction(size_t instructionPointer, int[] memory)
{
    immutable opcode = memory[instructionPointer] % 100;
    switch (opcode)
    {
    case Opcode.add:
        return addInstruction(instructionPointer, memory);
    case Opcode.multiply:
        return multiplyInstruction(instructionPointer, memory);
    case Opcode.halt:
        return haltInstruction(instructionPointer, memory);
    case Opcode.input:
        return inputInstruction(instructionPointer, memory);
    case Opcode.output:
        return outputInstruction(instructionPointer, memory);
    case Opcode.jumpIfTrue:
        return jumpIfTrueInstruction(instructionPointer, memory);
    case Opcode.jumpIfFalse:
        return jumpIfFalseInstruction(instructionPointer, memory);
    case Opcode.lessThan:
        return lessThanInstruction(instructionPointer, memory);
    case Opcode.equals:
        return equalsInstruction(instructionPointer, memory);
    default:
        throw new Exception("Invalid opcode %s".format(opcode));
    }
}

void main()
{
    auto memory = File("input", "r").readln.strip.splitter(",").map!(to!int).array;

    executeProgram(memory);
}

size_t executeProgram(int[] memory)
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
