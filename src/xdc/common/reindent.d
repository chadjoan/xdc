module xdc.common.reindent;

string reindent(size_t startingIndentLevel, string rawCode)
{
	// Right now this function is implemented with a cheesy best-effort
	// algorithm that doesn't actually understand D grammar.  It should
	// work in most of the time, but will have corner cases that can't be
	// fixed without implementing very complicated logic or a full-blown
	// D parser.

	import std.algorithm : min, max;
	import std.algorithm.searching : startsWith, endsWith;
	import std.array : appender;
	import std.string : lineSplitter, strip;
	import std.uni : isWhite;
	import std.utf : byChar;

	bool lineEndsWithContinuation = false; // Determined at each line scan
	bool indentForLineContinuation = false; // May persist between lines
	bool lineHasBlockStatement = false;
	bool oneLiner = false;
	ptrdiff_t indentLevel = startingIndentLevel;
	ptrdiff_t indentLevelBeforeThisLine = 0;
	ptrdiff_t indentLevelAfterThisLine = 0;
	ptrdiff_t indentLevelBeforeOneLiner = ptrdiff_t.min;
	auto code = appender!string;
	auto rawCodeLines = rawCode.lineSplitter;
	
	// Preallocate %110 of space used by input.  Wild ass guess as of 2018-09-19.
	code.reserve((rawCode.length * 10) / 11);
	
	while ( !rawCodeLines.empty )
	{
		string rawLine = rawCodeLines.front.strip;
		
		// Subject each line to two passes:
		// (1) Identify indentation level and state changes
		// (2) Apply indentation level
		//
		// This extra work is necessary because there are cases where you
		// won't know the appropriate indentation level for a line until
		// after the line has been examined (ex: when the line contains '}'),
		// or need to change the indentation level after emitting a line
		// (ex: when the line contains '{').

		// --------------------------------
		// Pass 1: Bookkeeping

		lineHasBlockStatement = false;
		indentLevelBeforeThisLine = indentLevel;
		indentLevelAfterThisLine  = indentLevel;

		auto rawCodeRange = rawLine.byChar;
		dchar prev = '\n';
		while ( !rawCodeRange.empty )
		{
			dchar ch = rawCodeRange.front;

			// Remove ch from the front of the range at the *end*, not the
			// beginning, of each iteration.  This allows .startsWith to
			// return what we expect in the code below, and without having
			// to meticuluously place rawCodeRange.popFront() at various
			// continuation points in the below code.
			scope(success)
			{
				rawCodeRange.popFront();
				prev = ch;
			}


			// Indentation counting and identification.
			// Note that this is pretty naive, and will get things like nested
			// one-liners wrong,
			//
			// ex:
			//   if ( expr1 )
			//       if ( expr2 )
			//           stmtA;
			//       else
			//           stmtB;
			//
			// ... would get reindented as
			//
			//   if ( expr1 )
			//       if ( expr2 )
			//           stmtA;
			//   else
			//       stmtB;
			//
			// This would require a parser to handle correctly, and is bad
			// practice regardless, so just don't do it.
			//
			switch(ch)
			{
				case '{':
				{
					if ( oneLiner )
					{
						indentLevelBeforeThisLine = indentLevelBeforeOneLiner;
						indentLevelAfterThisLine  = indentLevelBeforeOneLiner;
						oneLiner = false;
					}
					indentLevelAfterThisLine++;
					break;
				}

				case '}':
				{
					if ( oneLiner )
					{
						indentLevelBeforeThisLine = indentLevelBeforeOneLiner;
						indentLevelAfterThisLine  = indentLevelBeforeOneLiner;
						oneLiner = false;
					}
					indentLevelAfterThisLine--;
					break;
				}

				case ';':
				{
					if ( oneLiner )
					{
						indentLevelAfterThisLine = indentLevelBeforeOneLiner;
						oneLiner = false;
					}
					break;
				}
				
				default: break;
			}

			if ( !lineHasBlockStatement // Avoid indenting more than once per line, even if there are multiple statements.
			&&   rawCodeRange.startsWith("if","else","while","for",
					"foreach","foreach_reverse","switch","do")
			&&   prev.isWhite() )
			{
				lineHasBlockStatement = true;
				if ( !oneLiner ) // Checks for multiple levels of one-liners; only one semicolon to terminate all of them.
					indentLevelBeforeOneLiner = indentLevelBeforeThisLine;
				oneLiner = true;
				indentLevelAfterThisLine++;
			}
		}
		
		// Track whether this line determines it's own indentation level or
		// the just the next lines' indentation level(s).
		if ( rawLine.startsWith("}") )
			indentLevel = indentLevelAfterThisLine;
		else // unchanged indentation, block statements, {, etc.
			indentLevel = indentLevelBeforeThisLine;

		// Make sure the indentation level never falls below 0.
		indentLevel = max(indentLevel,0);

		// Determine line continuation status for this line and the next.
		lineEndsWithContinuation = false;

		if ( rawLine.endsWith("(","~","+","-",/+"*",+/"/",
			"&","|","^","=","?",":",",","<",">","%")
		&&   !rawLine.endsWith("*/","+/"))
		{
			lineEndsWithContinuation = true;
		}

		if ( rawLine.startsWith("~","+","-",/+"*",+/"/",
			"&","|","^","=","?",":",",","<",">","%")
		&&   !rawLine.startsWith("/*","*/"))
		{
			indentForLineContinuation = true;
		}

		// --------------------------------
		// Pass 2: Output formatting
		
		rawCodeRange = rawLine.byChar;
		
		/+ // Handy debug code.
		writeln("Outputting line '"~rawLine~"'");
		writeln("Attributes:");
		writeln("  lineEndsWithContinuation  = ", lineEndsWithContinuation);
		writeln("  indentForLineContinuation = ", indentForLineContinuation);
		writeln("  lineHasBlockStatement     = ", lineHasBlockStatement);
		writeln("  oneLiner                  = ", oneLiner);
		writeln("  indentLevel               = ", indentLevel);
		writeln("  indentLevelBeforeThisLine = ", indentLevelBeforeThisLine);
		writeln("  indentLevelAfterThisLine  = ", indentLevelAfterThisLine);
		writeln("  indentLevelBeforeOneLiner = ", indentLevelBeforeOneLiner);
		+/
		
		// Discard the input line's indentation.
		while ( !rawCodeRange.empty )
		{
			dchar ch = rawCodeRange.front;
			if ( !ch.isWhite )
				break;
			rawCodeRange.popFront();
		}
		
		// Output the calculated indentation.
		foreach( i; 0 .. indentLevel )
			code.put('\t');
		if ( indentForLineContinuation )
			code.put('\t');
		
		// Output the rest of the line.
		foreach( dchar ch; rawCodeRange )
			code.put(ch);
		
		// Move to the next line and
		// join all outgoing lines with the \n character.
		rawCodeLines.popFront();
		if ( !rawCodeLines.empty )
			code.put("\n");

		// This assignment must come after the 2nd pass, because it tracks
		// continuations that are meant for the /next/ line and not this one.
		indentForLineContinuation = lineEndsWithContinuation;
		
		// Similarly, this must come after the 2nd pass because it tracks
		// indentation for the next lines that may or may not have applied
		// to the current line.
		indentLevel = indentLevelAfterThisLine;
		
		// (Again) Make sure the indentation level never falls below 0.
		indentLevel = max(indentLevel,0);
	}
	
	return code.data;
}

unittest
{
	import std.format;
	import std.stdio;
	import std.string : strip;
	
	enum funcName = "reindent";
	size_t nFailures = 0;
	
	void aspectTest(size_t line = __LINE__, string file = __FILE__)
		(size_t startingIndentLevel, string rawText, string expectedResult)
	{
		string got = "";
		void onfail(string additionalInfo) {
			import std.string : replace;
			stderr.writefln("%s unittest failed:", funcName);
			if ( additionalInfo )
				stderr.writeln(additionalInfo);
			stderr.writeln("Input:");
			stderr.writeln(rawText.strip);
			stderr.writefln("(Starting indent level is %s)", startingIndentLevel);
			stderr.writeln("");
			stderr.writeln("Expected:");
			stderr.writeln(expectedResult.strip);
			stderr.writeln("");
			stderr.writeln("Got:");
			stderr.writeln(got);
			stderr.writeln("");
			stderr.writefln("Failed test was at line %s in file %s", line, file);
			stderr.writeln("");
			nFailures++;
		}

		got = reindent(startingIndentLevel, rawText.strip).strip;
		if ( got != expectedResult.strip )
		{
			onfail("");
			return;
		}

		got = reindent(startingIndentLevel, got).strip;
		if ( got != expectedResult.strip )
		{
			onfail(std.format.format(
				"NOTE: Normal test passed, but function (%s) is not idempotent. "~
				"(It is supposed to be idempotent.)",
				funcName));

			return;
		}
	}

	aspectTest(0,"","");
	aspectTest(0,"xyz","xyz");
	aspectTest(2,"xyz","\t\txyz");
	aspectTest(0,"x { y }","x { y }");
	aspectTest(2,"x { y }","\t\tx { y }"); // Right now, we are not adding/removing lines.  Just indents.

	aspectTest(0,
	`
		x {
		y
		}
	`,
	"x {\n\ty\n}");
	
	aspectTest(2,
	`
		x {
		y
		}
	`,
	"\t\tx {\n\t\t\ty\n\t\t}");
	
	aspectTest(2,
	`x {
		y
		}
	`,
	"\t\tx {\n\t\t\ty\n\t\t}");

	aspectTest(1,
	`
		if (expr) {
		y
		}
	`,
	"\tif (expr) {\n\t\ty\n\t}");

	aspectTest(1,
	`if (expr) {
		y
		}
	`,
	"\tif (expr) {\n\t\ty\n\t}");

	aspectTest(1, `
		void foo()
		{
			if (expr)
				return q;
			else
				return p;
		}
	`,
	"\tvoid foo()\n\t{\n\t\tif (expr)\n\t\t\treturn q;\n\t\telse\n\t\t\treturn p;\n\t}");

	aspectTest(1,
	`
		x
		if (expr) {
		y
		}
	`,
	"\tx\n\tif (expr) {\n\t\ty\n\t}");

	aspectTest(1,
	`
		x
		if (expr)
		{
		y
		}
	`,
	"\tx\n\tif (expr)\n\t{\n\t\ty\n\t}");

	aspectTest(1,
	`
		x
		if (expr1)
		{
			if (expr2)
				y
		}
	`,
	"\tx\n\tif (expr1)\n\t{\n\t\tif (expr2)\n\t\t\ty\n\t}");

	// This might not be what you'd expect, but this is a concession towards
	// making the thing easier to implement (at least while we lack better tools).
	aspectTest(1,
	`
		x
		if (expr1)
			if (expr2)
		{
				y
		}
	`,
	"\tx\n\tif (expr1)\n\t\tif (expr2)\n\t{\n\t\ty\n\t}");
	
	aspectTest(1,
	`
		x
		{
			f ( x +
				y);
		}
	`,
	"\tx\n\t{\n\t\tf ( x +\n\t\t\ty);\n\t}");
	
	aspectTest(1,
	`
		x
		{
			f ( x
				+ y);
		}
	`,
	"\tx\n\t{\n\t\tf ( x\n\t\t\t+ y);\n\t}");
	
	aspectTest(1,
	`
		x
		{
			f ( x
				+ y +
				z);
		}
	`,
	"\tx\n\t{\n\t\tf ( x\n\t\t\t+ y +\n\t\t\tz);\n\t}");
	
	aspectTest(1,
	`
		static Match n4( const char[] inputRange, size_t cursor, size_t ubound )
		{
				writefln("n4(%s,%s,%s)",inputRange,cursor,ubound);
		return Match.success(inputRange, cursor, cursor);
		}
	`,
"	static Match n4( const char[] inputRange, size_t cursor, size_t ubound )\n"~
"	{\n"~
"		writefln(\"n4(%s,%s,%s)\",inputRange,cursor,ubound);\n"~
"		return Match.success(inputRange, cursor, cursor);\n"~
"	}");
	
	aspectTest(1,
	`
		static Match n4( const char[] inputRange, size_t cursor, size_t ubound )
		{
				writefln("n4(%s,%s,%s)",inputRange,cursor,ubound);
		/* Epsilon */
		return Match.success(inputRange, cursor, cursor);
		}
	`,
"	static Match n4( const char[] inputRange, size_t cursor, size_t ubound )\n"~
"	{\n"~
"		writefln(\"n4(%s,%s,%s)\",inputRange,cursor,ubound);\n"~
"		/* Epsilon */\n"~
"		return Match.success(inputRange, cursor, cursor);\n"~
"	}");
	
	aspectTest(1,
	`
		static Match n4( const char[] inputRange, size_t cursor, size_t ubound )
		{
				writefln("n4(%s,%s,%s)",inputRange,cursor,ubound);

		return Match.success(inputRange, cursor, cursor);
		}
	`,
"	static Match n4( const char[] inputRange, size_t cursor, size_t ubound )\n"~
"	{\n"~
"		writefln(\"n4(%s,%s,%s)\",inputRange,cursor,ubound);\n"~
"		\n"~
"		return Match.success(inputRange, cursor, cursor);\n"~
"	}");
	
	aspectTest(1,
	`
		static Match n4( const char[] inputRange, size_t cursor, size_t ubound )
		{
				writefln("n4(%s,%s,%s)",inputRange,cursor,ubound);

		/* Epsilon */
		return Match.success(inputRange, cursor, cursor);

		}

	`,
"	static Match n4( const char[] inputRange, size_t cursor, size_t ubound )\n"~
"	{\n"~
"		writefln(\"n4(%s,%s,%s)\",inputRange,cursor,ubound);\n"~
"		\n"~
"		/* Epsilon */\n"~
"		return Match.success(inputRange, cursor, cursor);\n"~
"		\n"~
"	}");
	
	assert(nFailures == 0, std.format.format(
		"%s unittest had %s errors; see other error (above) messages for details.",
		funcName, nFailures));
}
