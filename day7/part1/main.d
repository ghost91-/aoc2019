module day7.part1.main;

import std;

auto outputRange(alias fn)()
{
    struct R
    {
        void put(Parameters!fn e)
        {
            fn(e);
        }
    }

    return R();
}

void main()
{
    auto memory = File("input", "r").readln.strip.splitter(",").map!(to!int).array;

    maxThrusterSignal(memory).writeln;
}

auto maxThrusterSignal(int[] memory)
{
    return iota(5).permutations
        .map!(phaseSettings => phaseSettings.fold!((input, phaseSetting) {
                int result;
                execute(memory.dup, [phaseSetting, input], outputRange!((int i) {
                    result = i;
                })());
                return result;
            })(0))
        .fold!max;
}

unittest
{
    //given
    auto memory = [
        3, 15, 3, 16, 1002, 16, 10, 16, 1, 16, 15, 15, 4, 15, 99, 0, 0
    ];

    // when
    immutable result = maxThrusterSignal(memory);

    // then
    assert(result == 43_210);
}

unittest
{
    //given
    auto memory = [
        3, 23, 3, 24, 1002, 24, 10, 24, 1002, 23, -1, 23, 101, 5, 23, 23, 1,
        24, 23, 23, 4, 23, 99, 0, 0
    ];

    // when
    immutable result = maxThrusterSignal(memory);

    // then
    assert(result == 54_321);
}

unittest
{
    //given
    auto memory = [
        3, 31, 3, 32, 1002, 32, 10, 32, 1001, 31, -2, 31, 1007, 31, 0, 33,
        1002, 33, 7, 33, 1, 33, 31, 31, 1, 32, 31, 31, 4, 31, 99, 0, 0, 0
    ];

    // when
    immutable result = maxThrusterSignal(memory);

    // then
    assert(result == 65_210);
}

alias Continue = Flag!"continue";

auto mode(const int value, const size_t paramIdx)
{
    return (value / (100 * 10 ^^ paramIdx)) % 10;
}

ref int param(const size_t ip, int[] memory, const size_t paramIdx)
{
    return mode(memory[ip], paramIdx) == 0 ? memory[memory[ip + 1 + paramIdx]]
        : memory[ip + 1 + paramIdx];
}

alias addInstruction = (ref size_t ip, int[] memory) => ({
    param(ip, memory, 2) = param(ip, memory, 0) + param(ip, memory, 1);
    ip += 4;
    return Continue.yes;
});

alias multiplyInstruction = (ref size_t ip, int[] memory) => ({
    param(ip, memory, 2) = param(ip, memory, 0) * param(ip, memory, 1);
    ip += 4;
    return Continue.yes;
});

alias inputInstruction = (ref size_t ip, int[] memory, ref input) => ({
    param(ip, memory, 0) = input.front;
    input.popFront();
    ip += 2;
    return Continue.yes;
});

alias outputInstruction = (ref size_t ip, int[] memory, ref output) => ({
    output.put(param(ip, memory, 0));
    ip += 2;
    return Continue.yes;
});

alias jumpIfTrueInstruction = (ref size_t ip, int[] memory) => ({
    if (param(ip, memory, 0) != 0)
        ip = param(ip, memory, 1).to!size_t;
    else
        ip += 3;
    return Continue.yes;
});

alias jumpIfFalseInstruction = (ref size_t ip, int[] memory) => ({
    if (param(ip, memory, 0) == 0)
        ip = param(ip, memory, 1).to!size_t;
    else
        ip += 3;
    return Continue.yes;
});

alias lessThanInstruction = (ref size_t ip, int[] memory) => ({
    param(ip, memory, 2) = param(ip, memory, 0) < param(ip, memory, 1) ? 1 : 0;
    ip += 4;
    return Continue.yes;
});

alias equalsInstruction = (ref size_t ip, int[] memory) => ({
    param(ip, memory, 2) = param(ip, memory, 0) == param(ip, memory, 1) ? 1 : 0;
    ip += 4;
    return Continue.yes;
});

alias haltInstruction = (ref size_t ip, int[] memory) => delegate() => Continue.no;

void execute(Input, Output)(int[] memory, Input input, Output output)
{
    size_t instructionPointer = 0;
    while (true)
    {
        immutable opcode = memory[instructionPointer] % 100;

        immutable _continue = [
            1: addInstruction(instructionPointer, memory),
            2: multiplyInstruction(instructionPointer, memory),
            3: inputInstruction(instructionPointer, memory, input),
            4: outputInstruction(instructionPointer, memory, output),
            5: jumpIfTrueInstruction(instructionPointer, memory),
            6: jumpIfFalseInstruction(instructionPointer, memory),
            7: lessThanInstruction(instructionPointer, memory),
            8: equalsInstruction(instructionPointer, memory),
            99: haltInstruction(instructionPointer, memory),
        ][opcode]();
        if (_continue == Continue.no)
            break;
    }
}

@("basic math")
{
    unittest
    {
        // given
        auto memory = [1, 0, 0, 0, 99];
        int[] input = [];

        // when
        execute(memory, input, nullSink);

        assert(memory == [2, 0, 0, 0, 99]);
    }

    unittest
    {
        // given
        auto memory = [2, 3, 0, 3, 99];
        int[] input = [];

        // when
        execute(memory, input, nullSink);

        assert(memory == [2, 3, 0, 6, 99]);
    }

    unittest
    {
        // given
        auto memory = [2, 4, 4, 5, 99, 0];
        int[] input = [];

        // when
        execute(memory, input, nullSink);

        assert(memory == [2, 4, 4, 5, 99, 9801]);
    }

    unittest
    {
        // given
        auto memory = [1, 1, 1, 4, 99, 5, 6, 0, 99];
        int[] input = [];

        // when
        execute(memory, input, nullSink);

        assert(memory == [30, 1, 1, 4, 2, 5, 6, 0, 99]);
    }

    unittest
    {
        // given
        auto memory = [
            1, 12, 2, 3, 1, 1, 2, 3, 1, 3, 4, 3, 1, 5, 0, 3, 2, 6, 1, 19, 1,
            19, 5, 23, 2, 9, 23, 27, 1, 5, 27, 31, 1, 5, 31, 35, 1, 35, 13,
            39, 1, 39, 9, 43, 1, 5, 43, 47, 1, 47, 6, 51, 1, 51, 13, 55, 1, 55,
            9, 59, 1, 59, 13, 63, 2, 63, 13, 67, 1, 67, 10, 71, 1, 71, 6, 75,
            2, 10, 75, 79, 2, 10, 79, 83, 1, 5, 83, 87, 2, 6, 87, 91, 1, 91, 6,
            95, 1, 95, 13, 99, 2, 99, 13, 103, 1, 103, 9, 107, 1, 10, 107,
            111, 2, 111, 13, 115, 1, 10, 115, 119, 1, 10, 119, 123, 2, 13,
            123, 127, 2, 6, 127, 131, 1, 13, 131, 135, 1, 135, 2, 139, 1, 139,
            6, 0, 99, 2, 0, 14, 0
        ];
        int[] input = [];

        // when
        execute(memory, input, nullSink);

        assert(memory[0] == 4_090_689);
    }

}

@(
        "Using position mode, consider whether the input is equal to 8; output 1 (if it is) or 0 (if it is not).")
{
    unittest
    {
        // given
        immutable data = "3,9,8,9,10,9,4,9,99,-1,8";
        auto memory = data.splitter(",").map!(to!int).array;
        int result;
        auto input = only(8);
        auto output = outputRange!((int e) { result = e; })();

        // when
        execute(memory, input, output);

        // then
        assert(result == 1);
    }

    unittest
    {
        // given
        immutable data = "3,9,8,9,10,9,4,9,99,-1,8";
        auto memory = data.splitter(",").map!(to!int).array;
        int result;
        auto input = only(7);
        auto output = outputRange!((int e) { result = e; })();

        // when
        execute(memory, input, output);

        // then
        assert(result == 0);
    }
}

@(
        "Using position mode, consider whether the input is less than 8; output 1 (if it is) or 0 (if it is not).")
{
    unittest
    {
        // given
        immutable data = "3,9,7,9,10,9,4,9,99,-1,8";
        auto memory = data.splitter(",").map!(to!int).array;
        int result;
        auto input = only(7);
        auto output = outputRange!((int e) { result = e; })();

        // when
        execute(memory, input, output);

        // then
        assert(result == 1);
    }

    unittest
    {
        // given
        immutable data = "3,9,7,9,10,9,4,9,99,-1,8";
        auto memory = data.splitter(",").map!(to!int).array;
        int result;
        auto input = only(8);
        auto output = outputRange!((int e) { result = e; })();

        // when
        execute(memory, input, output);

        // then
        assert(result == 0);
    }
}

@(
        "Using immediate mode, consider whether the input is equal to 8; output 1 (if it is) or 0 (if it is not).")
{
    unittest
    {
        // given
        immutable data = "3,3,1108,-1,8,3,4,3,99";
        auto memory = data.splitter(",").map!(to!int).array;
        int result;
        auto input = only(8);
        auto output = outputRange!((int e) { result = e; })();

        // when
        execute(memory, input, output);

        // then
        assert(result == 1);
    }

    unittest
    {
        // given
        immutable data = "3,3,1108,-1,8,3,4,3,99";
        auto memory = data.splitter(",").map!(to!int).array;
        int result;
        auto input = only(7);
        auto output = outputRange!((int e) { result = e; })();

        // when
        execute(memory, input, output);

        // then
        assert(result == 0);
    }
}

@(
        "Using immediate mode, consider whether the input is less than 8; output 1 (if it is) or 0 (if it is not).")
{
    unittest
    {
        // given
        immutable data = "3,3,1107,-1,8,3,4,3,99";
        auto memory = data.splitter(",").map!(to!int).array;
        int result;
        auto input = only(7);
        auto output = outputRange!((int e) { result = e; })();

        // when
        execute(memory, input, output);

        // then
        assert(result == 1);
    }

    unittest
    {
        // given
        immutable data = "3,3,1107,-1,8,3,4,3,99";
        auto memory = data.splitter(",").map!(to!int).array;
        int result;
        auto input = only(8);
        auto output = outputRange!((int e) { result = e; })();

        // when
        execute(memory, input, output);

        // then
        assert(result == 0);
    }
}

@(
        "Consider whether the input is below 8, equal to 8 or above 8; output 999 (below), 1000 (equal) or 1001 (above)")
{

    unittest
    {
        // given
        immutable data = "3,21,1008,21,8,20,1005,20,22,107,8,21,20,1006,20,31,1106,0,36,98,0,0,1002,21,125,20,4,20,1105,1,46,104,999,1105,1,46,1101,1000,1,20,4,20,1105,1,46,98,99";
        auto memory = data.splitter(",").map!(to!int).array;
        int result;
        auto input = only(7);
        auto output = outputRange!((int e) { result = e; })();

        // when
        execute(memory, input, output);

        // then
        assert(result == 999);
    }

    unittest
    {
        // given
        immutable data = "3,21,1008,21,8,20,1005,20,22,107,8,21,20,1006,20,31,1106,0,36,98,0,0,1002,21,125,20,4,20,1105,1,46,104,999,1105,1,46,1101,1000,1,20,4,20,1105,1,46,98,99";
        auto memory = data.splitter(",").map!(to!int).array;
        int result;
        auto input = only(8);
        auto output = outputRange!((int e) { result = e; })();

        // when
        execute(memory, input, output);

        // then
        assert(result == 1000);
    }

    unittest
    {
        // given
        immutable data = "3,21,1008,21,8,20,1005,20,22,107,8,21,20,1006,20,31,1106,0,36,98,0,0,1002,21,125,20,4,20,1105,1,46,104,999,1105,1,46,1101,1000,1,20,4,20,1105,1,46,98,99";
        auto memory = data.splitter(",").map!(to!int).array;
        int result;
        auto input = only(9);
        auto output = outputRange!((int e) { result = e; })();

        // when
        execute(memory, input, output);

        // then
        assert(result == 1001);
    }
}
