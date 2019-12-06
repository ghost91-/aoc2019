module day6.part2.main;

import std;

alias Pair = Tuple!(string, "key", string, "value");
alias pair = tuple!("key", "value");

void main()
{
    auto directOrbits = File("input", "r").byLine
        .map!(str => str.split(")"))
        .map!(pair => tuple(pair[1].to!string, pair[0].to!string))
        .assocArray;

    auto myAncestors = ancestorsWithDistances(directOrbits, "YOU").assocArray;
    auto commonAncestor = ancestorsWithDistances(directOrbits, "SAN").find!(
            it => it[0] in myAncestors).front;
    (commonAncestor[1] + myAncestors[commonAncestor[0]] - 2).writeln;
}

auto ancestorsWithDistances(string[string] directOrbits, string x)
{
    struct AncestorsWithDistances
    {
    private:
        string current;
        size_t count;

    public:

        bool empty() const @property
        {
            return current == "COM";
        }

        auto front() const
        {
            return tuple(directOrbits[current], count + 1);
        }

        void popFront()
        {
            current = directOrbits[current];
            count += 1;
        }

        AncestorsWithDistances save()
        {
            return this;
        }
    }

    return AncestorsWithDistances(x, 0);
}
