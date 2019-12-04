import std;

void main()
{
    iota(272_091, 815_433).map!(it => it.to!string)
        .filter!(it => it.zip(it.dropOne).canFind!(adjecent => adjecent[0] == adjecent[1]))
        .filter!(it => !it.zip(it.dropOne).canFind!(adjecent => adjecent[1] < adjecent[0]))
        .walkLength
        .writeln;
}
