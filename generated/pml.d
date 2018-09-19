module generated.pml;
import pegged.grammar;

struct GenericPML(TParseTree)
{
    struct PML
    {
    enum name = "PML";
    import std.typecons:Tuple, tuple;
    static TParseTree[Tuple!(string, size_t)] memo;
    static bool isRule(string s)
    {
        switch(s)
        {
            case "PML.Foo":
                return true;
            default:
                return false;
        }
    }
    mixin decimateTree;
    alias spacing Spacing;

    static TParseTree Foo(TParseTree p)
    {
        if(__ctfe)
        {
            return pegged.peg.named!(blank, "PML.Foo")(p);
        }
        else
        {
            if(auto m = tuple(`Foo`,p.end) in memo)
                return *m;
            else
            {
                TParseTree result = pegged.peg.named!(blank, "PML.Foo")(p);
                memo[tuple(`Foo`,p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree Foo(string s)
    {
        if(__ctfe)
        {
            return pegged.peg.named!(blank, "PML.Foo")(TParseTree("", false,[], s));
        }
        else
        {
            memo = null;
            return pegged.peg.named!(blank, "PML.Foo")(TParseTree("", false,[], s));
        }
    }
    static string Foo(GetName g)
    {
        return "PML.Foo";
    }

    static TParseTree opCall(TParseTree p)
    {
        TParseTree result = decimateTree(Foo(p));
        result.children = [result];
        result.name = "PML";
        return result;
    }

    static TParseTree opCall(string input)
    {
        if(__ctfe)
        {
            return PML(TParseTree(``, false, [], input, 0, 0));
        }
        else
        {
            memo = null;
            return PML(TParseTree(``, false, [], input, 0, 0));
        }
    }
    static string opCall(GetName g)
    {
        return "PML";
    }

    }
}

alias GenericPML!(ParseTree).PML PML;

