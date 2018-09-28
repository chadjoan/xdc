module xdc.parser_builder.grammar_node;

import xdc.parser_builder.op_type;

struct DCode
{
	string code;
	string entryFuncName;

	static DCode format(Args...)(size_t startingIndentLevel, string rawCodeFormatStr, Args args)
	{
        import std.format;
        return DCode(format(rawCodeFormatStr, args));
	}
	
	this(size_t startingIndentLevel, string rawCode)
	{
        code = reindent(startingIndentLevel, rawCode);
	}
	
	private static string reindent(size_t startingIndentLevel, string rawCode)
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
		auto dcode = appender!string;
		auto rawCodeLines = rawCode.lineSplitter;
		
		// Preallocate %110 of space used by input.  Wild ass guess as of 2018-09-19.
		dcode.reserve((rawCode.length * 10) / 11);
		
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
			while ( !rawCodeRange.empty )
			{
				dchar ch = rawCodeRange.front;

				// Remove ch from the front of the range at the *end*, not the
				// beginning, of each iteration.  This allows .startsWith to
				// return what we expect in the code below, and without having
				// to meticuluously place rawCodeRange.popFront() at various
				// continuation points in the below code.
				scope(success)
					rawCodeRange.popFront();

				/+
			// Convert those old mac newlines into something usable.
			// This is probably too paranoid (the input will be source code in
			// this project, which will always be unix/windows new lines, and
			// we probably wouldn't encounter lone '\r' characters in other
			// projects anyways, but I'm a stickler for correctness :/ ).
			if ( ch == '\r' && !rawCodeRange.startsWith("\r\n") )
				ch = '\n';
				+/

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
						"foreach","foreach_reverse","switch","do") )
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

			if ( rawLine.endsWith("~","+","-",/+"*",+/"/",
				"&","|","^","=","?",":",",","<",">","%") )
			{
				lineEndsWithContinuation = true;
			}

			if ( rawLine.startsWith("~","+","-",/+"*",+/"/",
				"&","|","^","=","?",":",",","<",">","%") )
			{
				indentForLineContinuation = true;
			}

			// --------------------------------
			// Pass 2: Output formatting
			
			rawCodeRange = rawLine.byChar;
			
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
				dcode.put('\t');
			if ( indentForLineContinuation )
				dcode.put('\t');
			
			// Output the rest of the line.
			foreach( dchar ch; rawCodeRange )
				dcode.put(ch);
			
			// Move to the next line and
			// join all outgoing lines with the \n character.
			rawCodeLines.popFront();
			if ( !rawCodeLines.empty )
				dcode.put("\n");

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
		
		return dcode.data;
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
				stderr.writefln("%s.%s unittest failed:", this.stringof, funcName);
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
		
		assert(nFailures == 0, std.format.format(
			"%s.%s unittest had %s errors; see other error (above) messages for details.",
			this.stringof, funcName, nFailures));
	}
}

template GrammarNodes(CallersElemType)
{
	alias GrammarNode Node;
	alias Node[] ChildList;

	abstract class GrammarNode
	{
		const OpType type;

		pure @property bool hasChildren() const            { return false; }
		pure @property const(ChildList) children() const   { assert(0); }
		@property ChildList children( ChildList newb )     { assert(0); }

		pure @property bool hasValues() const                        { return false; }
		pure @property const(CallersElemType[]) values() const       { assert(0); }
		@property CallersElemType[] values( CallersElemType[] newb ) { assert(0); }

		this( OpType type )
		{
			this.type = type;
		}

		void insertBack( Node child )
		{
			assert(0);
		}

		void insertBack( CallersElemType value )
		{
			assert(0);
		}

		final string toString( uint depth ) const
		{
			import std.algorithm : min;
			import std.array : replicate;
			import std.conv;

			string result = replicate(" ", min(depth*2,256)) ~ opTypeToString(type);

			if ( this.hasValues )
				result ~= " " ~ std.conv.to!string(this.values);

			if ( this.hasChildren )
				foreach( child; this.children )
					result ~= "\n" ~ child.toString(depth+1);

			return result;
		}

		final override string toString()
		{
			return toString(0);
		}

		protected string dCodeBody(ref string suffix, ref string[] symbolsById) const
		{
			assert(0);
		}

		DCode toDCode(ref string[] symbolsById) const
		{
			import std.conv;
			DCode result;

			auto thisFuncId = symbolsById.length;
			result.entryFuncName = "n"~std.conv.to!string(thisFuncId);
			symbolsById ~= result.entryFuncName;

			result.code = "";
			string suffix = "";

			const string funcParams =
				"( const "~CallersElemType.stringof~"[] inputRange, size_t cursor, size_t ubound )";

			string funcHeader =

			result.code ~=
				"\tstatic Match "~result.entryFuncName ~ funcParams ~ "\n"~
				"\t{\n"~
				"\t\twritefln(\""~result.entryFuncName~"(%s,%s,%s)\",inputRange,cursor,ubound);\n"~
				dCodeBody(suffix, symbolsById)~
				"\t}\n"~
				"\n"~suffix;

			return result;
		}

		DCode toDCode() const
		{
			string[] symbolsById = new string[0];
			return toDCode(symbolsById);
		}

		Node deepCopy(size_t depth = 0) const
		{
			import std.array : replicate;
			import std.range.primitives;
			import std.stdio;
			
			writefln("%s<%s.deepCopy(%s)>", "\t".replicate(depth), opTypeToString(type), depth);
			scope(exit)
				writefln("%s</%s.deepCopy(%s)>", "\t".replicate(depth), opTypeToString(type), depth);

			writefln("%s%s.classinfo.name == %s", "\t".replicate(depth), opTypeToString(type), this.classinfo.name);
			auto obj = typeid(this).create();
			writefln("%s%s.obj is null? == %s", "\t".replicate(depth), opTypeToString(type), obj is null);
			Node result = cast(Node)obj;
			//Node result = cast(Node)Object.factory(this.classinfo.name);
			assert(result);

			writefln("%s%s.hasValues == %s", "\t".replicate(depth), opTypeToString(type), this.hasValues);
			if ( this.hasValues && !this.values.empty )
			{
				writefln("%s%s.values == %s", "\t".replicate(depth), opTypeToString(type), this.values);
				auto newValues = new CallersElemType[this.values.length];
				for( size_t i = 0; i < this.values.length; i++ )
					newValues[i] = this.values[i];
				result.values = newValues;
			}

			writefln("%s%s.hasChildren == %s", "\t".replicate(depth), opTypeToString(type), this.hasChildren);
			if ( this.hasChildren && !this.children.empty )
			{
				auto newChildren = new Node[this.children.length];
				foreach( i, child; this.children )
					newChildren[i] = child ? child.deepCopy(depth+1) : null;
				result.children = newChildren;
			}

			return result;
		}
	}

	final class GrammarLeaf : GrammarNode
	{
		private CallersElemType[] m_values;   /* When type == OpType.literal */

		pure override @property bool hasValues() const
		{
			return true;
		}

		pure override @property const(CallersElemType[]) values() const
		{
			return m_values;
		}

		override @property CallersElemType[] values( CallersElemType[] newb )
		{
			return m_values = newb;
		}

		this()
		{
			super(OpType.literal);
			this.m_values = new CallersElemType[0];
		}

		this(size_t nElements)
		{
			super(OpType.literal);
			this.m_values = new CallersElemType[nElements];
		}

		this(CallersElemType elem)
		{
			super(OpType.literal);
			this.m_values = new CallersElemType[1];
			this.m_values[0] = elem;
		}

		override void insertBack( CallersElemType value )
		{
			m_values ~= value;
		}

		protected override string dCodeBody(ref string suffix, ref string[] symbolsById) const
		{
			assert( values.length == 1, "Flattened literals are currently unsupported." );
			return
				"\t\t/* Literal */\n"~
				"\t\tif ( cursor >= ubound )\n"~
				"\t\t\treturn Match.failure(inputRange);\n"~
				"\t\telse if ( inputRange[cursor] == '"~values[0]~"' )\n"~ // TODO!  How is equality/matching going to work for non-strings?
				"\t\t\treturn Match.success(inputRange, cursor, cursor+1);\n"~
				"\t\telse\n"~
				"\t\t\treturn Match.failure(inputRange);\n";
		}

	}

	abstract class GrammarParent : GrammarNode
	{
		private ChildList m_children;

		pure override @property bool hasChildren() const
		{
			return true;
		}

		pure override @property const(ChildList) children() const
		{
			return m_children;
		}

		override @property ChildList children( ChildList newb )
		{
			return m_children = newb;
		}

		this(OpType type)
		{
			assert(type != OpType.literal);
			super(type);
			this.m_children = new Node[0];
		}

		/+invariant()
		{
			assert( this.m_children !is null );
		}+/

		override void insertBack( Node child )
		{
			assert( type != OpType.literal );
			m_children ~= child;
		}
	}

	final class Sequence : GrammarParent
	{
		this()
		{
			super(OpType.sequence);
		}

		protected override string dCodeBody(ref string suffix, ref string[] symbolsById) const
		{
			import std.conv;
			assert(children.length >= 1);
			string result = "\t\t/* Sequence */\n";
			string prevCursor = "cursor";

			foreach ( i, child; children )
			{
				DCode childCode = child.toDCode(symbolsById);
				suffix ~= childCode.code;

				string thisMatchName = "m"~std.conv.to!string(i);
				result ~=
					"\t\tauto "~thisMatchName~" = "~childCode.entryFuncName~
							"(inputRange, "~prevCursor~", ubound);\n"~
					"\t\tif ( !"~thisMatchName~".successful )\n"~
					"\t\t\treturn Match.failure(inputRange);\n\n";

				prevCursor = "m"~std.conv.to!string(i)~".end";
			}

			result ~=
				"\t\treturn Match.success(inputRange, m0.begin, "~prevCursor~");\n";

			return result;
		}
	}

	final class EpsilonNode : GrammarNode
	{
		this() { super(OpType.epsilon); }

		protected override string dCodeBody(ref string suffix, ref string[] symbolsById) const
		{
			return
				"\t\t/* Epsilon */\n"~
				"\t\treturn Match.success(inputRange, cursor, cursor);\n";
		}
	}

	class OrderedChoice : GrammarParent
	{
		this() { super(OpType.orderedChoice); }
		this(OpType type) { super(type); }

		final protected override string dCodeBody(ref string suffix, ref string[] symbolsById) const
		{
			import std.conv;
			assert(children.length >= 1);
			string result = "\t\t/* Ordered Choice */\n";

			foreach ( i, child; children )
			{
				DCode childCode = child.toDCode(symbolsById);
				suffix ~= childCode.code;

				string thisMatchName = "m"~std.conv.to!string(i);
				result ~=
					"\t\tauto "~thisMatchName~" = "~childCode.entryFuncName~
							"(inputRange, cursor, ubound);\n"~
					"\t\tif ( "~thisMatchName~".successful )\n"~
					"\t\t\treturn Match.success("~
						"inputRange, "~
						thisMatchName~".begin, "~
						thisMatchName~".end);\n\n";
			}

			result ~=
				"\t\treturn Match.failure(inputRange);\n";

			return result;
		}
	}

	final class Maybe : OrderedChoice
	{
		this()
		{
			super(OpType.maybe);
			insertBack(new EpsilonNode);
		}
	}

	final class NegLookAhead : GrammarParent
	{
		this() { super(OpType.negLookAhead); }

		protected override string dCodeBody(ref string suffix, ref string[] symbolsById) const
		{
			assert(children.length == 1);

			DCode childCode = children[0].toDCode(symbolsById);
			suffix ~= childCode.code;

			return
				"\t\t/* Negative Lookahead */\n"~
				"\t\tauto m = "~childCode.entryFuncName~
						"(inputRange, newCursor, ubound);\n"~
				"\t\tif ( !m.successful )\n"~
				"\t\t\treturn Match.success(inputRange, cursor, cursor);\n"~
				"\t\telse\n"~
				"\t\t\treturn Match.failure(inputRange);\n";
		}
	}

	final class PosLookAhead : GrammarParent
	{
		this() { super(OpType.posLookAhead); }

		protected override string dCodeBody(ref string suffix, ref string[] symbolsById) const
		{
			assert(children.length == 1);

			DCode childCode = children[0].toDCode(symbolsById);
			suffix ~= childCode.code;

			return
				"\t\t/* Positive Lookahead */\n"~
				"\t\tauto m = "~childCode.entryFuncName~
						"(inputRange, newCursor, ubound);\n"~
				"\t\tif ( m.successful )\n"~
				"\t\t\treturn Match.success(inputRange, cursor, cursor);\n"~
				"\t\telse\n"~
				"\t\t\treturn Match.failure(inputRange);\n";
		}
	}

	final class FullRepeat : GrammarParent
	{
		this() { super(OpType.fullRepeat); }

		protected override string dCodeBody(ref string suffix, ref string[] symbolsById) const
		{
			assert(children.length == 1);

			DCode childCode = children[0].toDCode(symbolsById);
			suffix ~= childCode.code;

			return
				"\t\t/* Repetition */\n"~
				"\t\tsize_t newCursor = cursor;\n"~
				"\t\twhile ( true )\n"~
				"\t\t{\n"~
				"\t\t\tauto m = "~childCode.entryFuncName~
							"(inputRange, newCursor, ubound);\n"~
				"\t\t\tif ( !m.successful )\n"~
				"\t\t\t\tbreak;\n"~
				"\n"~
				"\t\t\tnewCursor = m.end;\n"~
				"\t\t}\n"~
				"\n"~
				"\t\treturn Match.success(inputRange, cursor, newCursor);\n";
		}
	}

	Node flattenLiterals( Node n )
	{
		if ( n.type != OpType.sequence )
			return n;

		bool doFlatten = true;
		size_t elemCount = 0;
		foreach( child; n.children )
		{
			if ( child.type != OpType.literal )
			{
				doFlatten = false;
				break;
			}

			elemCount += child.values.length;
		}

		if ( !doFlatten )
			return n;

		auto newNode = new GrammarLeaf();
		size_t i = 0;

		auto newValues = new CallersElemType[elemCount];
		foreach( child; n.children )
			foreach ( val; child.values )
				newValues[i++] = val;
		newNode.values = newValues;

		return newNode;
	}

}
