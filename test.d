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
