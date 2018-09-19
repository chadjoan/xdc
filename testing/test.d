/+
import pegged.grammar;
import std.stdio;

mixin(grammar(`
TestGrammar:
    Formal      <  Variable "As" Type
    Variable    <- identifier
    Type        <- "Integer" / "Long"
    Spacing     <- space / "_" eol
`));

mixin(grammar(`
TestGrammar2:
    Formal      <  Variable "As" spacing Type
    Variable    <- identifier
    Type        <- "Integer" / "Long"
    Spacing     <- space / "_" eol
`));

int main()
{
    writeln(TestGrammar("foo As Integer"));
    writeln(TestGrammar("foo AsInteger")); // Also succeeds?!
    writeln(TestGrammar2("foo AsInteger")); // Fails as expected
    writeln(TestGrammar2("foo As Integer")); // Fails, but intend to succeed.
    return 0;
}
+/

import pegged.grammar;
import std.stdio;

mixin(grammar(`
TestGrammar:
    Test       <- (Visibility Spacing+)? "Function"
    Visibility <~ "Private"
    Spacing    <: space / "_" eol
`));

int main()
{
    writeln(TestGrammar("Private Function"));
    return 0;
}

/+
enum string testGrammar = ` 
TestGrammar:

Root < A B* !.
A <- 'a'
B <- 'b'
`;

import pegged.grammar;
import std.stdio;

mixin(grammar(testGrammar));

void main()
{
	stdout.writefln("%s", TestGrammar.Root("ab b bb b"));
}

+/
