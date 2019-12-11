module day11.part2.main;

import std;
import core.thread;

void main()
{
    auto memory = File("input", "r").readln.strip.splitter(",").map!(to!long).array;
    memory.length = 2048;
    auto sensorData = new Pipe!long();
    auto actions = new Pipe!long();
    long[long[2]] colors;
    colors[[0, 0]] = 1;

    Scheduler().schedule(createFiber(memory, sensorData, actions))
        .schedule(readSensorFiber(actions, sensorData, colors)).run();

    auto minX = colors.keys.map!(it => it[0]).minElement;
    auto minY = colors.keys.map!(it => it[1]).minElement;
    auto maxX = colors.keys.map!(it => it[0]).maxElement;
    auto maxY = colors.keys.map!(it => it[1]).maxElement;

    iota(maxY, minY - 1, -1).map!(i => iota(minX, maxX + 1)
            .map!(j => colors.getOrElse([j, i], 0) == 0 ? ' ' : '#'))
        .each!writeln;
}

auto getOrElse(K, V)(V[K] data, K key, V fallback)
{
    if (long* value = key in data)
        return *value;
    else
        return fallback;
}

auto newDirection(long direction, long turn)
{
    switch (turn)
    {
    case 0:
        return (direction + 1) % 4;
    case 1:
        return (direction - 1 + 4) % 4;
    default:
        throw new Exception("Invalid turn: %s".format(turn));
    }
}

auto newPosition(long[2] position, long direction)
{
    switch (direction)
    {
    case 0:
        position[1] += 1;
        break;
    case 1:
        position[0] -= 1;
        break;
    case 2:
        position[1] -= 1;
        break;
    case 3:
        position[0] += 1;
        break;
    default:
        throw new Exception("Invalid direction: %s".format(direction));
    }
    return position;
}

auto readSensorFiber(Pipe!long i, Pipe!long o, long[long[2]] colors)
{
    return new Fiber(() {
        auto currentPosition = [0, 0].to!(long[2]);
        auto currentDirection = 0L;

        while (true)
        {
            o.put(colors.getOrElse(currentPosition, 0));
            Fiber.yield;
            if (i.empty)
                break;
            immutable newColor = i.front;
            i.popFront();
            colors[currentPosition] = newColor;
            immutable turn = i.front;
            i.popFront();
            currentDirection = currentDirection.newDirection(turn);
            currentPosition = currentPosition.newPosition(currentDirection);
        }
    });
}

class Pipe(T)
{
private:
    T[] data;

public:
    this(T[] data = [])
    {
        this.data = data;
    }

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

ref long param(long[] memory, const size_t ip, const size_t rb, const size_t paramIdx)
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

alias addInstruction = (long[] memory, ref size_t ip, const size_t rb) => () {
    param(memory, ip, rb, 2) = param(memory, ip, rb, 0) + param(memory, ip, rb, 1);
    ip += 4;
    return Continue.yes;
};

alias multiplyInstruction = (long[] memory, ref size_t ip, const size_t rb) => () {
    param(memory, ip, rb, 2) = param(memory, ip, rb, 0) * param(memory, ip, rb, 1);
    ip += 4;
    return Continue.yes;
};

alias inputInstruction = (long[] memory, ref size_t ip, const size_t rb, ref input) => () {
    Fiber.yield();
    param(memory, ip, rb, 0) = input.front;
    input.popFront();
    ip += 2;
    return Continue.yes;
};

alias outputInstruction = (long[] memory, ref size_t ip, const size_t rb, ref output) => () {
    output.put(param(memory, ip, rb, 0));
    ip += 2;
    return Continue.yes;
};

alias jumpIfTrueInstruction = (long[] memory, ref size_t ip, const size_t rb) => () {
    if (param(memory, ip, rb, 0) != 0)
        ip = param(memory, ip, rb, 1).to!size_t;
    else
        ip += 3;
    return Continue.yes;
};

alias jumpIfFalseInstruction = (long[] memory, ref size_t ip, const size_t rb) => () {
    if (param(memory, ip, rb, 0) == 0)
        ip = param(memory, ip, rb, 1).to!size_t;
    else
        ip += 3;
    return Continue.yes;
};

alias lessThanInstruction = (long[] memory, ref size_t ip, const size_t rb) => () {
    param(memory, ip, rb, 2) = param(memory, ip, rb, 0) < param(memory, ip, rb, 1) ? 1 : 0;
    ip += 4;
    return Continue.yes;
};

alias equalsInstruction = (long[] memory, ref size_t ip, const size_t rb) => () {
    param(memory, ip, rb, 2) = param(memory, ip, rb, 0) == param(memory, ip, rb, 1) ? 1 : 0;
    ip += 4;
    return Continue.yes;
};

alias adjustRelativeBaseInstruction = (long[] memory, ref size_t ip, ref size_t rb) => () {
    rb += param(memory, ip, rb, 0);
    ip += 2;
    return Continue.yes;
};

alias haltInstruction = () => delegate() => Continue.no;

auto createFiber(Input, Output)(long[] memory, Input input, Output output)
{
    return new Fiber(() {
        size_t ip = 0;
        size_t rb = 0;
        while (true)
        {
            immutable opcode = memory[ip] % 100;
            immutable _continue = [
                1: addInstruction(memory, ip, rb),
                2: multiplyInstruction(memory, ip, rb),
                3: inputInstruction(memory, ip, rb, input),
                4: outputInstruction(memory, ip, rb, output),
                5: jumpIfTrueInstruction(memory, ip, rb),
                6: jumpIfFalseInstruction(memory, ip, rb),
                7: lessThanInstruction(memory, ip, rb),
                8: equalsInstruction(memory, ip, rb),
                9: adjustRelativeBaseInstruction(memory, ip, rb),
                99: haltInstruction(),
            ][opcode]();
            if (_continue == Continue.no)
                break;
        }
    });
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
