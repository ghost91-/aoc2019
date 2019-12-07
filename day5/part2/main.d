module day5.part2.main;

import std;

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

alias inputInstruction = (ref size_t ip, int[] memory, input) => ({
    param(ip, memory, 0) = input.front;
    input.popFront();
    ip += 2;
    return Continue.yes;
});

alias outputInstruction = (ref size_t ip, int[] memory, output) => ({
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
    size_t ip = 0;
    while (true)
    {
        immutable opcode = memory[ip] % 100;
        immutable _continue = [
            1: addInstruction(ip, memory),
            2: multiplyInstruction(ip, memory),
            3: inputInstruction(ip, memory, input),
            4: outputInstruction(ip, memory, output),
            5: jumpIfTrueInstruction(ip, memory),
            6: jumpIfFalseInstruction(ip, memory),
            7: lessThanInstruction(ip, memory),
            8: equalsInstruction(ip, memory),
            99: haltInstruction(ip, memory),
        ][opcode]();
        if (_continue == Continue.no)
            break;
    }
}

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

    int result;
    execute(memory, only(5), outputRange!((int e) { result = e; })());
    result.writeln;
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
