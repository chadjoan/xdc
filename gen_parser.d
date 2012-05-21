import std.file;
import std.stdio;
import std.conv;

import pegged.examples.dgrammar;
import pegged.examples.c;
import pegged.grammar;
import pegged.peg;

void main()
{
	if ( !std.file.exists("generated") )
		std.file.mkdir("generated");
	if ( std.file.exists("generated/dparser.d") )
		std.file.remove("generated/dparser.d");
	std.file.write("generated/dparser.d",//"Hello world!");
		to!string(
			"module generated.dparser;\n"~
			"import pegged.grammar;\n"~
			"import pegged.peg;\n"~
			"\n"~grammar(Cgrammar)));
}