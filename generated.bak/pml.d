module generated.pml;
import pegged.grammar;

struct GenericPML(TParseTree)
{
    struct PML
    {
    enum name = "PML";
    static bool isRule(string s)
    {
        switch(s)
        {
            case "PML.PatternExpressions":
            case "PML.PatternExpression":
            case "PML.BlockExpression":
            case "PML.BinaryExpression":
            case "PML.AndExpression":
            case "PML.HasExpression":
            case "PML.UnaryExpression":
            case "PML.UnaryOp":
            case "PML.AtomicMatch":
            case "PML.RelativePath":
            case "PML.Path":
            case "PML.Type":
            case "PML.Capture":
            case "PML.Integer":
            case "PML.Identifier":
                return true;
            default:
                return false;
        }
    }
    mixin decimateTree;
    alias spacing Spacing;

    static TParseTree PatternExpressions(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.zeroOrMore!(PatternExpression), name ~ ".PatternExpressions")(p);
    }

    static TParseTree PatternExpressions(string s)
    {
        return pegged.peg.named!(pegged.peg.zeroOrMore!(PatternExpression), name ~ ".PatternExpressions")(TParseTree("", false,[], s));
    }

    static TParseTree PatternExpression(TParseTree p)
    {
        return pegged.peg.named!(BinaryExpression, name ~ ".PatternExpression")(p);
    }

    static TParseTree PatternExpression(string s)
    {
        return pegged.peg.named!(BinaryExpression, name ~ ".PatternExpression")(TParseTree("", false,[], s));
    }

    static TParseTree BlockExpression(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("{"), PatternExpression, pegged.peg.literal!("}")), name ~ ".BlockExpression")(p);
    }

    static TParseTree BlockExpression(string s)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("{"), PatternExpression, pegged.peg.literal!("}")), name ~ ".BlockExpression")(TParseTree("", false,[], s));
    }

    static TParseTree BinaryExpression(TParseTree p)
    {
        return pegged.peg.named!(AndExpression, name ~ ".BinaryExpression")(p);
    }

    static TParseTree BinaryExpression(string s)
    {
        return pegged.peg.named!(AndExpression, name ~ ".BinaryExpression")(TParseTree("", false,[], s));
    }

    static TParseTree AndExpression(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, HasExpression, pegged.peg.option!(PatternExpression), UnaryExpression, pegged.peg.option!(pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!(";"), pegged.peg.option!(PatternExpression)))), name ~ ".AndExpression")(p);
    }

    static TParseTree AndExpression(string s)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, HasExpression, pegged.peg.option!(PatternExpression), UnaryExpression, pegged.peg.option!(pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!(";"), pegged.peg.option!(PatternExpression)))), name ~ ".AndExpression")(TParseTree("", false,[], s));
    }

    static TParseTree HasExpression(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, AtomicMatch, pegged.peg.option!(Capture), pegged.peg.literal!("has"), BlockExpression), name ~ ".HasExpression")(p);
    }

    static TParseTree HasExpression(string s)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, AtomicMatch, pegged.peg.option!(Capture), pegged.peg.literal!("has"), BlockExpression), name ~ ".HasExpression")(TParseTree("", false,[], s));
    }

    static TParseTree UnaryExpression(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.or!(pegged.peg.spaceAnd!(Spacing, UnaryOp, UnaryExpression), BlockExpression, AtomicMatch), name ~ ".UnaryExpression")(p);
    }

    static TParseTree UnaryExpression(string s)
    {
        return pegged.peg.named!(pegged.peg.or!(pegged.peg.spaceAnd!(Spacing, UnaryOp, UnaryExpression), BlockExpression, AtomicMatch), name ~ ".UnaryExpression")(TParseTree("", false,[], s));
    }

    static TParseTree UnaryOp(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.or!(pegged.peg.literal!("any"), pegged.peg.literal!("at_least"), pegged.peg.literal!("at_most"), pegged.peg.literal!("maybe"), pegged.peg.literal!("one_of"), pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("between"), pegged.peg.literal!("("), Integer, pegged.peg.literal!(","), Integer, pegged.peg.literal!(")"))), name ~ ".UnaryOp")(p);
    }

    static TParseTree UnaryOp(string s)
    {
        return pegged.peg.named!(pegged.peg.or!(pegged.peg.literal!("any"), pegged.peg.literal!("at_least"), pegged.peg.literal!("at_most"), pegged.peg.literal!("maybe"), pegged.peg.literal!("one_of"), pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("between"), pegged.peg.literal!("("), Integer, pegged.peg.literal!(","), Integer, pegged.peg.literal!(")"))), name ~ ".UnaryOp")(TParseTree("", false,[], s));
    }

    static TParseTree AtomicMatch(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.or!(pegged.peg.literal!("."), pegged.peg.spaceAnd!(Spacing, Type, Capture), Type, RelativePath, pegged.peg.spaceAnd!(Spacing, RelativePath, Capture)), name ~ ".AtomicMatch")(p);
    }

    static TParseTree AtomicMatch(string s)
    {
        return pegged.peg.named!(pegged.peg.or!(pegged.peg.literal!("."), pegged.peg.spaceAnd!(Spacing, Type, Capture), Type, RelativePath, pegged.peg.spaceAnd!(Spacing, RelativePath, Capture)), name ~ ".AtomicMatch")(TParseTree("", false,[], s));
    }

    static TParseTree RelativePath(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("."), Path), name ~ ".RelativePath")(p);
    }

    static TParseTree RelativePath(string s)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("."), Path), name ~ ".RelativePath")(TParseTree("", false,[], s));
    }

    static TParseTree Path(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, Identifier, pegged.peg.literal!("."), Path), name ~ ".Path")(p);
    }

    static TParseTree Path(string s)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, Identifier, pegged.peg.literal!("."), Path), name ~ ".Path")(TParseTree("", false,[], s));
    }

    static TParseTree Type(TParseTree p)
    {
        return pegged.peg.named!(Identifier, name ~ ".Type")(p);
    }

    static TParseTree Type(string s)
    {
        return pegged.peg.named!(Identifier, name ~ ".Type")(TParseTree("", false,[], s));
    }

    static TParseTree Capture(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("$"), Identifier), name ~ ".Capture")(p);
    }

    static TParseTree Capture(string s)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("$"), Identifier), name ~ ".Capture")(TParseTree("", false,[], s));
    }

    static TParseTree Integer(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.oneOrMore!(pegged.peg.charRange!('0', '9')), name ~ ".Integer")(p);
    }

    static TParseTree Integer(string s)
    {
        return pegged.peg.named!(pegged.peg.oneOrMore!(pegged.peg.charRange!('0', '9')), name ~ ".Integer")(TParseTree("", false,[], s));
    }

    static TParseTree Identifier(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, pegged.peg.or!(pegged.peg.charRange!('a', 'z'), pegged.peg.charRange!('A', 'Z'), pegged.peg.literal!("_")), pegged.peg.zeroOrMore!(pegged.peg.or!(pegged.peg.charRange!('a', 'z'), pegged.peg.charRange!('A', 'Z'), pegged.peg.charRange!('0', '9'), pegged.peg.literal!("_")))), name ~ ".Identifier")(p);
    }

    static TParseTree Identifier(string s)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, pegged.peg.or!(pegged.peg.charRange!('a', 'z'), pegged.peg.charRange!('A', 'Z'), pegged.peg.literal!("_")), pegged.peg.zeroOrMore!(pegged.peg.or!(pegged.peg.charRange!('a', 'z'), pegged.peg.charRange!('A', 'Z'), pegged.peg.charRange!('0', '9'), pegged.peg.literal!("_")))), name ~ ".Identifier")(TParseTree("", false,[], s));
    }

    static TParseTree opCall(TParseTree p)
    {
        TParseTree result = decimateTree(PatternExpressions(p));
        result.children = [result];
        result.name = "PML";
        return result;
    }

    static TParseTree opCall(string input)
    {
        return PML(TParseTree(``, false, [], input, 0, 0));
    }
    }
}

alias GenericPML!(ParseTree).PML PML;

