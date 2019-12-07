module day7.part2.main;

import std;

class Subject(T)
{
    T[] data;

    void put(T e)
    {
        data ~= e;
    }

    bool empty() const @property
    {
        return data.empty;
    }

    T front()
    {
        return data.front;
    }

    void popFront()
    {
        data.popFront();
    }
}

/* For some reason it is not possible to chain the amps directly: This always
   results in an assertion in range/package.d:1009 */
auto calculateOutput(int[] phaseSettings, int[] memory)
{
    auto memories = phaseSettings.map!(i => memory.dup).array;

    auto input0 = new Subject!int();
    auto input1 = new Subject!int();
    auto input2 = new Subject!int();
    auto input3 = new Subject!int();
    auto input4 = new Subject!int();

    input0.put(0);
    auto amp0 = applyProgram([phaseSettings[0]].chain(input0), memories[0]);
    input1.put(amp0.front);
    auto amp1 = applyProgram([phaseSettings[1]].chain(input1), memories[1]);
    input2.put(amp1.front);
    auto amp2 = applyProgram([phaseSettings[2]].chain(input2), memories[2]);
    input3.put(amp2.front);
    auto amp3 = applyProgram([phaseSettings[3]].chain(input3), memories[3]);
    input4.put(amp3.front);
    auto amp4 = applyProgram([phaseSettings[4]].chain(input4), memories[4]);

    int result;
    while (!amp4.empty)
    {
        result = amp4.front;
        input0.put(amp4.front);
        amp0.popFront();
        input1.put(amp0.front);
        amp1.popFront();
        input2.put(amp1.front);
        amp2.popFront();
        input3.put(amp2.front);
        amp3.popFront();
        input4.put(amp3.front);
        amp4.popFront();
    }
    return result;
}

void main()
{
    auto memory = File("input", "r").readln.strip.splitter(",").map!(to!int).array;
    immutable backup = memory.dup;

    iota(5, 10).permutations
        .map!(phaseSettings => phaseSettings.array.calculateOutput(memory))
        .fold!max
        .writeln;

    assert(backup == memory);
}

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

interface Instruction
{
    Continue execute(ref size_t instructionPointer, int[] memory);
}

class AddInstruction : Instruction
{
private:
    Parameter value1, value2, outAddress;

public:
    this(size_t instructionPointer, int[] memory)
    {
        value1 = parameter(instructionPointer, memory, 0);
        value2 = parameter(instructionPointer, memory, 1);
        outAddress = parameter(instructionPointer, memory, 2);
    }

    override Continue execute(ref size_t instructionPointer, int[] memory)
    {
        outAddress.derefIfNeeded(memory) = value1.derefIfNeeded(
                memory) + value2.derefIfNeeded(memory);
        instructionPointer += 4;
        return Continue.yes;
    }
}

class MultiplyInstruction : Instruction
{
private:
    Parameter value1, value2, outAddress;

public:
    this(size_t instructionPointer, int[] memory)
    {
        value1 = parameter(instructionPointer, memory, 0);
        value2 = parameter(instructionPointer, memory, 1);
        outAddress = parameter(instructionPointer, memory, 2);
    }

    override Continue execute(ref size_t instructionPointer, int[] memory)
    {
        outAddress.derefIfNeeded(memory) = value1.derefIfNeeded(
                memory) * value2.derefIfNeeded(memory);
        instructionPointer += 4;
        return Continue.yes;
    }
}

class InputInstruction(alias ir) : Instruction
{
private:
    Parameter outAddress;

public:
    this(size_t instructionPointer, int[] memory)
    {
        outAddress = parameter(instructionPointer, memory, 0);
    }

    override Continue execute(ref size_t instructionPointer, int[] memory)
    {
        outAddress.derefIfNeeded(memory) = ir.front;
        ir.popFront();
        instructionPointer += 2;
        return Continue.yes;
    }
}

class OutputInstruction : Instruction
{
private:
    Parameter value;

public:
    this(size_t instructionPointer, int[] memory)
    {
        value = parameter(instructionPointer, memory, 0);
    }

    override Continue execute(ref size_t instructionPointer, int[] memory)
    {
        yield(value.derefIfNeeded(memory));
        instructionPointer += 2;
        return Continue.yes;
    }
}

class JumpIfTrueInstruction : Instruction
{
private:
    Parameter toBeChecked, target;

public:
    this(size_t instructionPointer, int[] memory)
    {
        toBeChecked = parameter(instructionPointer, memory, 0);
        target = parameter(instructionPointer, memory, 1);
    }

    override Continue execute(ref size_t instructionPointer, int[] memory)
    {
        if (toBeChecked.derefIfNeeded(memory) != 0)
            instructionPointer = target.derefIfNeeded(memory).to!size_t;
        else
            instructionPointer += 3;
        return Continue.yes;
    }
}

class JumpIfFalseInstruction : Instruction
{
private:
    Parameter toBeChecked, target;

public:
    this(size_t instructionPointer, int[] memory)
    {
        toBeChecked = parameter(instructionPointer, memory, 0);
        target = parameter(instructionPointer, memory, 1);
    }

    override Continue execute(ref size_t instructionPointer, int[] memory)
    {
        if (toBeChecked.derefIfNeeded(memory) == 0)
            instructionPointer = target.derefIfNeeded(memory).to!size_t;
        else
            instructionPointer += 3;
        return Continue.yes;
    }
}

class LessThanInstruction : Instruction
{
private:
    Parameter value1, value2, outAddress;

public:
    this(size_t instructionPointer, int[] memory)
    {
        value1 = parameter(instructionPointer, memory, 0);
        value2 = parameter(instructionPointer, memory, 1);
        outAddress = parameter(instructionPointer, memory, 2);
    }

    override Continue execute(ref size_t instructionPointer, int[] memory)
    {
        outAddress.derefIfNeeded(memory) = value1.derefIfNeeded(
                memory) < value2.derefIfNeeded(memory) ? 1 : 0;
        instructionPointer += 4;
        return Continue.yes;
    }
}

class EqualsInstruction : Instruction
{
private:
    Parameter value1, value2, outAddress;

public:
    this(size_t instructionPointer, int[] memory)
    {
        value1 = parameter(instructionPointer, memory, 0);
        value2 = parameter(instructionPointer, memory, 1);
        outAddress = parameter(instructionPointer, memory, 2);
    }

    override Continue execute(ref size_t instructionPointer, int[] memory)
    {
        outAddress.derefIfNeeded(memory) = value1.derefIfNeeded(
                memory) == value2.derefIfNeeded(memory) ? 1 : 0;
        instructionPointer += 4;
        return Continue.yes;
    }
}

class HaltInstruction : Instruction
{
    this(size_t instructionPointer, int[] memory)
    {
    }

    override Continue execute(ref size_t instructionPointer, int[] memory)
    {
        return Continue.no;
    }
}

Instruction nextInstruction(alias ir)(size_t instructionPointer, int[] memory)
{
    immutable opcode = memory[instructionPointer] % 100;
    switch (opcode)
    {
    case Opcode.add:
        return new AddInstruction(instructionPointer, memory);
    case Opcode.multiply:
        return new MultiplyInstruction(instructionPointer, memory);
    case Opcode.input:
        return new InputInstruction!(ir)(instructionPointer, memory);
    case Opcode.output:
        return new OutputInstruction(instructionPointer, memory);
    case Opcode.jumpIfTrue:
        return new JumpIfTrueInstruction(instructionPointer, memory);
    case Opcode.jumpIfFalse:
        return new JumpIfFalseInstruction(instructionPointer, memory);
    case Opcode.lessThan:
        return new LessThanInstruction(instructionPointer, memory);
    case Opcode.equals:
        return new EqualsInstruction(instructionPointer, memory);
    case Opcode.halt:
        return new HaltInstruction(instructionPointer, memory);
    default:
        throw new Exception("Invalid opcode %s".format(opcode));
    }
}

auto applyProgram(IR)(IR ir, int[] memory)
{
    return new Generator!int({
        size_t instructionPointer = 0;
        while (true)
        {
            auto instruction = nextInstruction!(ir)(instructionPointer, memory);
            immutable _continue = instruction.execute(instructionPointer, memory);
            if (_continue == Continue.no)
                break;
        }
    });
}
