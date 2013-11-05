import std.file;
import std.stdio;
import std.conv;

import pegged.examples.dgrammar;
import pegged.examples.c;
import pegged.grammar;

import xdc.grammars.pmlgrammar;

void main()
{
	
	std.file.write("src/xdc/generated/parsers.d",
		to!string(
			"module xdc.generated.parsers;\n"~
			"import pegged.grammar;\n"~
			"\n"~grammar!(Memoization.no)(Dgrammar ~ DgrammarExtensions)~
            "\n"~grammar(pmlGrammar)));
	
}

const DgrammarExtensions = `

XdcFinalOutput <- !.*
`;
