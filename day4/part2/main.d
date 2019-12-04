import std;

void main()
{
    iota(272_091, 815_433).map!(it => it.to!string)
        .filter!(it => !it.zip(it.drop(1)).canFind!(adjecent => adjecent[1] < adjecent[0]))
        .map!(it => 0 ~ it ~ 0)
        .filter!(it => it.zip(it.drop(1), it.drop(2), it.drop(3)).canFind!(adjecent => adjecent[0] != adjecent[1]
                && adjecent[1] == adjecent[2] && adjecent[2] != adjecent[3]))
        .walkLength
        .writeln;
}
