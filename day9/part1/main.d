module day9.part1.main;

import std;
import core.thread;

void main()
{
    auto memory = File("input", "r").readln.strip.splitter(",").map!(to!long).array;
    memory.length = 2048;
    auto input = [1L];
    auto output = outputRange!((long e) { e.writeln; })();
    Scheduler().schedule(createFiber(memory, input, output)).run();
}

struct Scheduler
{
private:
    Fiber[] fibers = [];
public:
    auto schedule(Fiber fiber)
    {
        this.fibers ~= fiber;
        return this;
    }

    void run()
    {
        while (!fibers.empty)
        {
            fibers.each!(fiber => fiber.call());
            fibers = fibers.filter!(f => f.state != Fiber.State.TERM).array;
        }
    }

}

alias Continue = Flag!"continue";

auto mode(const long value, const size_t paramIdx)
{
    return (value / (100 * 10 ^^ paramIdx)) % 10;
}

ref long param(const size_t ip, long[] memory, const size_t rb, const size_t paramIdx)
{
    immutable m = mode(memory[ip], paramIdx);
    switch (m)
    {
    case 0:
        return memory[memory[ip + 1 + paramIdx]];
    case 1:
        return memory[ip + 1 + paramIdx];
    case 2:
        return memory[rb + memory[ip + 1 + paramIdx]];
    default:
        throw new Exception("Invalid parameter mode %s".format(m));
    }
}

alias addInstruction = (ref size_t ip, long[] memory, ref size_t rb) => ({
    param(ip, memory, rb, 2) = param(ip, memory, rb, 0) + param(ip, memory, rb, 1);
    ip += 4;
    return Continue.yes;
});

alias multiplyInstruction = (ref size_t ip, long[] memory, ref size_t rb) => ({
    param(ip, memory, rb, 2) = param(ip, memory, rb, 0) * param(ip, memory, rb, 1);
    ip += 4;
    return Continue.yes;
});

alias inputInstruction = (ref size_t ip, long[] memory, ref size_t rb, ref input) => ({
    Fiber.yield();
    param(ip, memory, rb, 0) = input.front;
    input.popFront();
    ip += 2;
    return Continue.yes;
});

alias outputInstruction = (ref size_t ip, long[] memory, ref size_t rb, ref output) => ({
    output.put(param(ip, memory, rb, 0));
    ip += 2;
    return Continue.yes;
});

alias jumpIfTrueInstruction = (ref size_t ip, long[] memory, ref size_t rb) => ({
    if (param(ip, memory, rb, 0) != 0)
        ip = param(ip, memory, rb, 1).to!size_t;
    else
        ip += 3;
    return Continue.yes;
});

alias jumpIfFalseInstruction = (ref size_t ip, long[] memory, ref size_t rb) => ({
    if (param(ip, memory, rb, 0) == 0)
        ip = param(ip, memory, rb, 1).to!size_t;
    else
        ip += 3;
    return Continue.yes;
});

alias lessThanInstruction = (ref size_t ip, long[] memory, ref size_t rb) => ({
    param(ip, memory, rb, 2) = param(ip, memory, rb, 0) < param(ip, memory, rb, 1) ? 1 : 0;
    ip += 4;
    return Continue.yes;
});

alias equalsInstruction = (ref size_t ip, long[] memory, ref size_t rb) => ({
    param(ip, memory, rb, 2) = param(ip, memory, rb, 0) == param(ip, memory, rb, 1) ? 1 : 0;
    ip += 4;
    return Continue.yes;
});

alias adjustRelatieBaseInstruction = (ref size_t ip, long[] memory, ref size_t rb) => ({
    rb += param(ip, memory, rb, 0);
    ip += 2;
    return Continue.yes;
});

alias haltInstruction = (ref size_t ip, long[] memory, ref size_t rb) => delegate() => Continue.no;

auto createFiber(Input, Output)(long[] memory, Input input, Output output)
{
    return new Fiber(() {
        size_t ip = 0;
        size_t rb = 0;
        while (true)
        {
            immutable opcode = memory[ip] % 100;
            immutable _continue = [
                1: addInstruction(ip, memory, rb),
                2: multiplyInstruction(ip, memory, rb),
                3: inputInstruction(ip, memory, rb, input),
                4: outputInstruction(ip, memory, rb, output),
                5: jumpIfTrueInstruction(ip, memory, rb),
                6: jumpIfFalseInstruction(ip, memory, rb),
                7: lessThanInstruction(ip, memory, rb),
                8: equalsInstruction(ip, memory, rb),
                9: adjustRelatieBaseInstruction(ip, memory, rb),
                99: haltInstruction(ip, memory, rb),
            ][opcode]();
            if (_continue == Continue.no)
                break;
        }
    });
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

@("basic math")
{
    unittest
    {
        // given
        auto memory = [1, 0, 0, 0, 99L];
        long[] input = [];

        // when
        Scheduler().schedule(createFiber(memory, input, nullSink)).run();

        // then
        assert(memory == [2, 0, 0, 0, 99]);
    }

    unittest
    {
        // given
        auto memory = [2, 3, 0, 3, 99L];
        long[] input = [];

        // when
        Scheduler().schedule(createFiber(memory, input, nullSink)).run();

        // then
        assert(memory == [2, 3, 0, 6, 99]);
    }

    unittest
    {
        // given
        auto memory = [2, 4, 4, 5, 99, 0L];
        long[] input = [];

        // when
        Scheduler().schedule(createFiber(memory, input, nullSink)).run();

        // then
        assert(memory == [2, 4, 4, 5, 99, 9801]);
    }

    unittest
    {
        // given
        auto memory = [1, 1, 1, 4, 99, 5, 6, 0, 99L];
        long[] input = [];

        // when
        Scheduler().schedule(createFiber(memory, input, nullSink)).run();

        // then
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
            6, 0, 99, 2, 0, 14, 0L
        ];
        long[] input = [];

        // when
        Scheduler().schedule(createFiber(memory, input, nullSink)).run();

        // then
        assert(memory[0] == 4_090_689);
    }

}

@(
        "Using position mode, consider whether the input is equal to 8; output 1 (if it is) or 0 (if it is not).")
{
    unittest
    {
        // given
        auto memory = [3, 9, 8, 9, 10, 9, 4, 9, 99, -1, 8L];
        long result;
        auto input = only(8);
        auto output = outputRange!((long e) { result = e; })();

        // when
        Scheduler().schedule(createFiber(memory, input, output)).run();

        // then
        assert(result == 1);
    }

    unittest
    {
        // given
        auto memory = [3, 9, 8, 9, 10, 9, 4, 9, 99, -1, 8L];
        long result;
        auto input = only(7);
        auto output = outputRange!((long e) { result = e; })();

        // when
        Scheduler().schedule(createFiber(memory, input, output)).run();

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
        auto memory = [3, 9, 7, 9, 10, 9, 4, 9, 99, -1, 8L];
        long result;
        auto input = only(7);
        auto output = outputRange!((long e) { result = e; })();

        // when
        Scheduler().schedule(createFiber(memory, input, output)).run();

        // then
        assert(result == 1);
    }

    unittest
    {
        // given
        auto memory = [3, 9, 7, 9, 10, 9, 4, 9, 99, -1, 8L];
        long result;
        auto input = only(8);
        auto output = outputRange!((long e) { result = e; })();

        // when
        Scheduler().schedule(createFiber(memory, input, output)).run();

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
        auto memory = [3, 3, 1108, -1, 8, 3, 4, 3, 99L];
        long result;
        auto input = only(8);
        auto output = outputRange!((long e) { result = e; })();

        // when
        Scheduler().schedule(createFiber(memory, input, output)).run();

        // then
        assert(result == 1);
    }

    unittest
    {
        // given
        auto memory = [3, 3, 1108, -1, 8, 3, 4, 3, 99L];
        long result;
        auto input = only(7);
        auto output = outputRange!((long e) { result = e; })();

        // when
        Scheduler().schedule(createFiber(memory, input, output)).run();

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
        auto memory = [3, 3, 1107, -1, 8, 3, 4, 3, 99L];
        long result;
        auto input = only(7);
        auto output = outputRange!((long e) { result = e; })();

        // when
        Scheduler().schedule(createFiber(memory, input, output)).run();

        // then
        assert(result == 1);
    }

    unittest
    {
        // given
        auto memory = [3, 3, 1107, -1, 8, 3, 4, 3, 99L];
        long result;
        auto input = only(8);
        auto output = outputRange!((long e) { result = e; })();

        // when
        Scheduler().schedule(createFiber(memory, input, output)).run();

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
        auto memory = [
            3, 21, 1008, 21, 8, 20, 1005, 20, 22, 107, 8, 21, 20, 1006, 20,
            31, 1106, 0, 36, 98, 0, 0, 1002, 21, 125, 20, 4, 20, 1105, 1, 46,
            104, 999, 1105, 1, 46, 1101, 1000, 1, 20, 4, 20, 1105, 1, 46, 98, 99L
        ];
        long result;
        auto input = only(7);
        auto output = outputRange!((long e) { result = e; })();

        // when
        Scheduler().schedule(createFiber(memory, input, output)).run();

        // then
        assert(result == 999);
    }

    unittest
    {
        // given
        auto memory = [
            3, 21, 1008, 21, 8, 20, 1005, 20, 22, 107, 8, 21, 20, 1006, 20,
            31, 1106, 0, 36, 98, 0, 0, 1002, 21, 125, 20, 4, 20, 1105, 1, 46,
            104, 999, 1105, 1, 46, 1101, 1000, 1, 20, 4, 20, 1105, 1, 46, 98, 99L
        ];
        long result;
        auto input = only(8);
        auto output = outputRange!((long e) { result = e; })();

        // when
        Scheduler().schedule(createFiber(memory, input, output)).run();

        // then
        assert(result == 1000);
    }

    unittest
    {
        // given
        auto memory = [
            3, 21, 1008, 21, 8, 20, 1005, 20, 22, 107, 8, 21, 20, 1006, 20,
            31, 1106, 0, 36, 98, 0, 0, 1002, 21, 125, 20, 4, 20, 1105, 1, 46,
            104, 999, 1105, 1, 46, 1101, 1000, 1, 20, 4, 20, 1105, 1, 46, 98, 99L
        ];
        long result;
        auto input = only(9);
        auto output = outputRange!((long e) { result = e; })();

        // when
        Scheduler().schedule(createFiber(memory, input, output)).run();

        // then
        assert(result == 1001);
    }
}

@("relative mode")
{
    unittest
    {
        // given
        immutable program = [
            109, 1, 204, -1, 1001, 100, 1, 100, 1008, 100, 16, 101, 1006, 101, 0,
            99L
        ];
        long[] memory = program.dup;
        memory.length = 128;
        long[] result;
        long[] input = [];
        auto output = outputRange!((long e) { result ~= e; })();

        // when
        Scheduler().schedule(createFiber(memory, input, output)).run();

        // then
        assert(result == program);
    }
}

@("large numbers")
{
    unittest
    {
        // given
        immutable program = [1102, 34_915_192, 34_915_192, 7, 4, 7, 99, 0L];
        long[] memory = program.dup;
        long result;
        long[] input = [];
        auto output = outputRange!((long e) { result = e; })();

        // when
        Scheduler().schedule(createFiber(memory, input, output)).run();

        // then
        assert(result < 10_000_000_000_000_000 && result > 999_999_999_999_999);
    }

    unittest
    {
        // given
        immutable program = [104, 1_125_899_906_842_624, 99L];
        long[] memory = program.dup;
        long result;
        long[] input = [];
        auto output = outputRange!((long e) { result = e; })();

        // when
        Scheduler().schedule(createFiber(memory, input, output)).run();

        // then
        assert(result == 1_125_899_906_842_624);
    }
}
