
import std.file;
import std.conv;

//version = TRACE_NFA;
//version( TRACE_NFA )
	import std.stdio;

//version = TRACE_CTFE;

import generated.dparser;

alias short PatternOpArgument;
alias long SyntaxElement;

enum : SyntaxElement
{
	AST_EXPRESSION              = 0x0001_0000_0000_0000,
		AST_UNARY_EXPR          = 0x0000_0001_0000_0000 | AST_EXPRESSION,
			AST_NEGATE_EXPR     = 0x0000_0000_0001_0000 |  AST_UNARY_EXPR,
			AST_COMPLIMENT_EXPR = 0x0000_0000_0002_0000 |  AST_UNARY_EXPR,
			AST_POST_ADD_EXPR   = 0x0000_0000_0003_0000 |  AST_UNARY_EXPR,
			AST_POST_SUB_EXPR   = 0x0000_0000_0004_0000 |  AST_UNARY_EXPR,
			AST_PRE_ADD_EXPR    = 0x0000_0000_0005_0000 |  AST_UNARY_EXPR,
			AST_PRE_SUB_EXPR    = 0x0000_0000_0006_0000 |  AST_UNARY_EXPR,
		AST_BINARY_EXPR         = 0x0000_0002_0000_0000 | AST_EXPRESSION,
		    AST_AND_EXPR        = 0x0000_0000_0001_0000 |  AST_BINARY_EXPR,
		    AST_OR_EXPR         = 0x0000_0000_0002_0000 |  AST_BINARY_EXPR,
			AST_XOR_EXPR        = 0x0000_0000_0003_0000 |  AST_BINARY_EXPR,
			AST_AND_AND_EXPR    = 0x0000_0000_0004_0000 |  AST_BINARY_EXPR,
			AST_OR_OR_EXPR      = 0x0000_0000_0005_0000 |  AST_BINARY_EXPR,
			AST_ADD_EXPR        = 0x0000_0000_0006_0000 |  AST_BINARY_EXPR,
		AST_TRINARY_EXPR        = 0x0000_0003_0000_0000 | AST_EXPRESSION,
		AST_NARY_EXPR           = 0x0000_0004_0000_0000 | AST_EXPRESSION,
	AST_STATEMENT               = 0x0002_0000_0000_0000,
}

bool isA( SyntaxElement leafier, SyntaxElement rootier )
{
	SyntaxElement mask = 0;
	
	if ( rootier & 0x0000_0000_FFFF_FFFF )
	{
		if ( rootier & 0x0000_0000_0000_FFFF )
			mask = 0xFFFF_FFFF_FFFF_FFFF;
		else
			mask = 0xFFFF_FFFF_FFFF_0000;
	}
	else
	{
		if ( rootier & 0x0000_FFFF_FFFF_FFFF )
			mask = 0xFFFF_FFFF_0000_0000;
		else
			mask = 0xFFFF_0000_0000_0000;
	}
	
	return (leafier & mask) == rootier;
}

unittest
{
	assert( isA(AST_EXPRESSION,AST_EXPRESSION) );
	assert( isA(AST_NEGATE_EXPR,AST_NEGATE_EXPR) );
	assert( isA(AST_NEGATE_EXPR,AST_EXPRESSION) );
	assert( isA(AST_NEGATE_EXPR,AST_UNARY_EXPR) );
	assert( !isA(AST_EXPRESSION,AST_STATEMENT) );
	assert( !isA(AST_NEGATE_EXPR,AST_BINARY_EXPR) );
	assert( !isA(AST_NEGATE_EXPR,AST_STATEMENT) );
	assert( !isA(AST_NEGATE_EXPR,AST_COMPLIMENT_EXPR) );
	assert(false);
}

/+
struct Scope
{
	string path;
	SymbolTable* symbols;
}

struct SymbolTable
{
	private bool[string] allSymbols;

}

import std.variant;
struct AstNodeContents
{
	SyntaxElement token;
	Variant       payload;
}

struct ParseTree
{
	AstNodeContents metadata;
    dstring grammarName;
    dstring ruleName;
    bool success;
    dstring[] capture;
    Pos begin, end;
    ParseTree[] children;
    
    dstring name() @property { return grammarName ~ "."d ~ ruleName;}
    
    dstring toString(int level = 0) @property
    {
        dstring tabs;        
        foreach(i; 0..level) tabs ~= "  "d;
        dstring ch;
        foreach(child; children)
            ch ~= tabs ~ child.toString(level+1);
        return tabs ~ name ~ ": "d
             ~ "["d ~ begin.toString() ~ " - "d ~ end.toString() ~ "]"d
             ~ to!dstring(capture)
//                        ~ next[0..to!int(capture[0])] ~ "` / `" ~ next[to!int(capture[0])..$] ~ "`") 
             ~ (children.length > 0 ? "\n"d ~ ch : "\n"d);
    }
}


struct Pos
{
    size_t index; // linear index
    size_t line;  // input line
    size_t col;   // input column
    
    dstring toString() @property
    {
        return "[index: "d ~ to!dstring(index) ~ ", line: "d ~ to!dstring(line) ~ ", col: "d ~ to!dstring(col) ~ "]"d;
    }
}

+/

bool isToken( SyntaxElement op )
{
	return 0 == (op & 0x8000_0000_0000_0000);
}



int opCmp( const SyntaxElement t1, const SyntaxElement t2 )
{
	if ( t2 > t1 )
		return 1;
	else if ( t2 == t1 )
		return 0;
	else
		return -1;
}

string itoa(long num)
{
	//__ctfeWriteln("sup!");
	const string digitLookup = "0123456789";
	if ( num < 0 )
		return "-" ~ itoa(-num);
	else if ( num < 10 )
		return [digitLookup[cast(size_t)num]];
	else
		return itoa(num / 10) ~ itoa(num % 10);
}


string boolToStr(bool val)
{
	if ( val ) return "true";
	else       return "false";
}

template definePatternOps( alias definitionType )
{
	const string definePatternOps = 
		// ------------------------------------------------------------------------//
		//                                                                         //
		//             (          Name           ,   arg3 arg2 arg1 stem, lhs?  )  //
		//                                                                         //
		definitionType!("OP_STEM_MASK"           , 0xFFFF_0000_0000_0000, false ) ~
		definitionType!("OP_MATCH"               , 0x8001_0000_0000_0000, false ) ~ // Indicates "final" NFA states.
		definitionType!("OP_NOOP"                , 0x8002_0000_0000_0000, false ) ~
		definitionType!("OP_ENTER_NODE"          , 0x8003_0000_0000_0000, false ) ~
		definitionType!("OP_FLATTEN_NODE"        , 0x8004_0000_0000_0000, false ) ~
		definitionType!("OP_UNORDERED"           , 0x8005_0000_0000_0000, false ) ~
		definitionType!("OP_PICK"                , 0x8006_0000_0000_0000, false ) ~
		definitionType!("OP_BEGIN"               , 0x8007_0000_0000_0000, false ) ~ // Like ( in textual regular expressions.
		definitionType!("OP_END"                 , 0x8008_0000_0000_0000, false ) ~ // Like ) in textual regular expressions.
		definitionType!("OP_OR"                  , 0x8009_0000_0000_0000, true  ) ~ // Like | in textual regular expressions.
		definitionType!("OP_MAYBE"               , 0x800A_0000_0000_0000, true  ) ~ // Like ? in textual regular expressions.
		definitionType!("OP_REPEAT_STEM"         , 0x800B_0000_0000_0000, true  ) ~
		definitionType!("OP_RECURSE"             , 0x800C_0000_0000_0000, false ) ~
		definitionType!("OP_CONCAT"              , 0x800D_0000_0000_0000, false ) ~
		definitionType!("OP_CAPTURE_STEM"        , 0x800E_0000_0000_0000, false ) ~
		definitionType!("OP_CAPTURE_RANGE_STEM"  , 0x800F_0000_0000_0000, false ) ~
		"";
}


template patternEnumDefinition( string name, ulong contents, bool hasLhs)
{
	const string patternEnumDefinition = "\t" ~name~ " = "~ itoa(contents) ~ ",\n";
}

const patternOpEnum =
	"enum : SyntaxElement\n{\n"~
	definePatternOps!(patternEnumDefinition)~
	"}\n";

//pragma(msg, patternOpEnum);
mixin(patternOpEnum);


template stemHasLhsDefinition( string name, ulong contents, bool hasLhs)
{
	const string stemHasLhsDefinition =
		"\t\tcase "~itoa(contents)~": return "~boolToStr(hasLhs)~"; break;\n";
}

const stemHasLhsFuncStr =
	"bool stemHasLhs(SyntaxElement op)\n"~
	"{\n"~
	"	auto stem = op & OP_STEM_MASK;\n"~
	"	switch ( stem )\n"~
	"	{\n"~
	definePatternOps!(stemHasLhsDefinition)~
	"		default: assert(0);\n"~
	"	}\n"~
	"	assert(0);\n"~
	"}\n";

//pragma(msg,stemHasLhsFuncStr);
mixin(stemHasLhsFuncStr);


template patternOpToStringDefinition( string name, ulong contents, bool hasLhs)
{
	const string patternOpToStringDefinition =
		"\t\tcase "~itoa(contents)~`: return "`~name~`"; break;`~"\n";
}

const patternOpToStringFuncStr =
	"string stemToString(SyntaxElement op)\n"~
	"{\n"~
	"	if ( isToken(op) )\n"~
	"		return \"TOKEN \"~to!string(op);\n"~
	"	auto stem = op & OP_STEM_MASK;\n"~
	"	switch ( stem )\n"~
	"	{\n"~
	definePatternOps!(patternOpToStringDefinition)~
	"		default: assert(0);\n"~
	"	}\n"~
	"	assert(0);\n"~
	"}\n";

//pragma(msg,patternOpToStringFuncStr);
mixin(patternOpToStringFuncStr);

string syntaxElemToString( SyntaxElement p )
{
	if ( isToken(p) )
		return itoa(p);
	else
		return stemToString(p);
}

enum
{
	OP_REPEAT_MIN_ARGSHIFT = 16,
	OP_REPEAT_MAX_ARGSHIFT = 32,
	OP_CAPTURE_ID_ARGMASK  = 0x0000_0000_FFFF_0000, // The identifier for a capture.
	OP_CAPTURE_ID_ARGSHIFT = 16,
	OP_REPEAT_MIN_ARGMASK  = 0x0000_0000_FFFF_0000, // The minimum amount of times it must repeat.
	OP_REPEAT_MAX_ARGMASK  = 0x0000_FFFF_0000_0000, // The maximum amount of times it must repeat.
	OP_ARG_INFINITY = 0x7FFF,
}


SyntaxElement OP_REPEAT()
{
	return OP_REPEAT(0, OP_ARG_INFINITY);
}


SyntaxElement OP_REPEAT_AT_LEAST(PatternOpArgument nTimes)
{
	return OP_REPEAT(nTimes, OP_ARG_INFINITY);
}

SyntaxElement OP_REPEAT_AT_MOST(PatternOpArgument nTimes)
{
	return OP_REPEAT(0,nTimes);
}



SyntaxElement OP_REPEAT_EXACTLY(PatternOpArgument nTimes)
{
	return OP_REPEAT(nTimes,nTimes);
}

SyntaxElement OP_REPEAT(PatternOpArgument min, PatternOpArgument max)
{
	SyntaxElement min64 = min;
	SyntaxElement max64 = max;
	return OP_REPEAT_STEM
		| (min64 << OP_REPEAT_MIN_ARGSHIFT)
		| (max64 << OP_REPEAT_MAX_ARGSHIFT);
}

SyntaxElement OP_CAPTURE(PatternOpArgument captureId)
{
	SyntaxElement id64 = captureId;
	return OP_CAPTURE_STEM | (id64 << OP_CAPTURE_ID_ARGSHIFT);
}

SyntaxElement OP_CAPTURE_RANGE(PatternOpArgument captureId)
{
	SyntaxElement id64 = captureId;
	return OP_CAPTURE_RANGE_STEM | (id64 << OP_CAPTURE_ID_ARGSHIFT);
}

//============================================================================//
//                        NFA definitions.                                    //
//============================================================================//

alias int NfaLabel;

struct NfaState
{
	NfaLabel label = -1;
	SyntaxElement op;
	NfaArrow out1 = null;
	NfaArrow out2 = null;
	
	this(SyntaxElement op, NfaState* out1, NfaState *out2)
	{
		this.op = op;
		this.out1 = out1;
		this.out2 = out2;
	}
	
	int opCmp( ref const NfaState* s ) const
	{
		if ( this.op < s.op )
			return -1;
		else if ( this.op > s.op )
			return 1;
		else
			return 0;
	}
	
	private struct NfaToDPrinter
	{
		int depth = 0;
		const(NfaState*)[] visited;
	}
	
	string toD() const
	{
		int nodeId = 0;
		NfaToDPrinter n2dp;
		n2dp.visited = new NfaState*[0];
		return toD(n2dp);
	}
	
	string toD(ref NfaToDPrinter n2dp) const
	{
		string lhsFunc = "";
		string rhsFunc = "";

		version( TRACE_NFA )
		{
			auto tabs = std.array.replicate("\t",n2dp.depth);
			stdout.writefln("%stoD(%s)", tabs, label);
			n2dp.depth++;
			scope(exit) n2dp.depth--;
		}
		
		n2dp.visited ~= &this; //NfaStatePrintingMetadata(&this,label);
	
		auto result =
		"bool matches_"~to!string(label)~"(SyntaxElement[] tokens)\n"
		"{\n";
		
		if ( isToken(op) )
		{
			result ~=
			"	if ( tokens.length == 0 )\n"~
			"		return false;\n"~
			"\n"~
			"	SyntaxElement t = tokens[0];\n"~
			"	if ( t != "~to!string(op)~" )\n"~
			"		return false;\n"~
			"	tokens = tokens[1..$];\n\n";
		}
		
		int recurse(const NfaState* outState, ref string funcStr)
		{
			// First, try to return an already-visited label.
			for ( int i = 0; i < n2dp.visited.length; i++ )
				if ( n2dp.visited[i] is outState )
					return n2dp.visited[i].label;
		
			//// Allocate a new node ID and save it so we can return it to the caller.
			//n2dp.curNodeId++;
			//auto idCaptured = n2dp.curNodeId;
			
			// First encounter: generate a function for it.
			funcStr = outState.toD(n2dp);
			
			//return idCaptured;
			return outState.label;
		}
		
		if ( out1 != null && out2 != null )
		{
			auto lhsId = recurse(out1, lhsFunc);
			auto rhsId = recurse(out2, rhsFunc);
			
			result ~=
			"	if ( matches_"~to!string(lhsId)~"(tokens) )\n"~
			"		return true;\n"~
			"	else if ( matches_"~to!string(rhsId)~"(tokens) )\n"~
			"		return true;\n"~
			"	else\n"~
			"		return false;\n";
		}
		else if ( out1 != null || out2 != null )
		{
			const(NfaState)* outState = out1;
			if ( outState is null )
				outState = out2;
			
			auto lhsId = recurse(outState, lhsFunc);
			
			result ~=
			"	if ( matches_"~to!string(lhsId)~"(tokens) )\n"~
			"		return true;\n"~
			"	else\n"~
			"		return false;\n";
		}
		else if ( op == OP_MATCH )
		{
			result ~= 
			"	return true;\n";
		}
		else
		{
			result ~=
			`	throw new Exception("Error in NFA generation: leaf node without OP_MATCH");`~"\n";
		}
		
		result ~=
		"}\n\n";
		
		return lhsFunc~rhsFunc~result;
	}
}

private void nfaLabelAndIndex( ref NfaState*[] nfaArray, NfaState* startNode )
{
	if ( startNode is null )
		return;
	
	foreach( ref otherNode; nfaArray )
		if ( otherNode is startNode )
			return; // Already visited.
	
	startNode.label = nfaArray.length;
	nfaArray ~= startNode;
	
	nfaLabelAndIndex(nfaArray, startNode.out1);
	nfaLabelAndIndex(nfaArray, startNode.out2);
}

NfaState*[] nfaLabelAndIndex( NfaState* startNode )
{
	auto nfaArray = new NfaState*[0];
	nfaLabelAndIndex(nfaArray, startNode);
	return nfaArray;
}

//============================================================================//
//                        NFA consruction functions.                          //
//============================================================================//

alias NfaState* NfaArrow;

struct NfaFragment
{
	NfaState*   startNode;
	NfaArrow*[] danglingArrows;
	
	this(NfaState* startNode, NfaArrow* danglingArrow)
	{
		this.startNode = startNode;
		this.danglingArrows = new NfaArrow*[1];
		this.danglingArrows[0] = danglingArrow;
	}
	
	NfaFragment deepCopy() const
	{
		NfaFragment newFrag;
		newFrag.danglingArrows = new NfaArrow*[0];
		m_deepCopy(this.startNode,    this.danglingArrows,
		         newFrag.startNode, newFrag.danglingArrows);
		return newFrag;
	}

	private static void m_deepCopy(
		const NfaState*   oldState,
		const NfaArrow*[] danglingArrowsIn, 
		out   NfaState*   newState,
		out   NfaArrow*[] danglingArrowsOut)
	{
		if ( oldState is null )
			newState = null;
		else
		{
		
			newState = new NfaState(oldState.op, null, null);
			m_deepCopy(oldState.out1, danglingArrowsIn, newState.out1, danglingArrowsOut);
			m_deepCopy(oldState.out2, danglingArrowsIn, newState.out2, danglingArrowsOut);
			
			foreach ( ref NfaArrow* arrowPtr; danglingArrowsIn )
			{
				if      ( arrowPtr is &oldState.out1 )
					danglingArrowsOut ~= &newState.out1;
				else if ( arrowPtr is &oldState.out2 )
					danglingArrowsOut ~= &newState.out2;
			}
		}
	}
}


// Attach all of the given danglingArrows to the destinationState.
void patch( NfaArrow*[] danglingArrows, NfaState* destinationState )
{
	foreach ( NfaArrow* arrowPtr; danglingArrows )
		*arrowPtr = destinationState;
}


NfaState*[] createNfa( SyntaxElement[] patternElements )
{
	NfaFragment[] fragmentStack = new NfaFragment[0];
	int elemNum = 0;
	getNextFragment(fragmentStack, OP_BEGIN ~ patternElements ~ OP_END, elemNum);
	auto frag = fragmentStack[0];
	auto matchState = new NfaState(OP_MATCH, null, null);
	patch(frag.danglingArrows, matchState);
	
	//if ( fragmentStack.length != 1 )
	//	stdout.writefln("Warning: fragmentStack.length == %s.", fragmentStack.length);
	
	return nfaLabelAndIndex(frag.startNode);
}

version( TRACE_NFA ) {
	int indent = 0;
}

private void getNextFragment(
	ref NfaFragment[] fragmentStack,
	SyntaxElement[]   patternElements,
	ref int elemNum )
{
	version( TRACE_NFA ) {
		auto tabs = std.array.replicate("\t",indent);
		stdout.writefln("%s%s: getNextFragment() fragmentStack.length = %s",tabs,__LINE__,fragmentStack.length);
		indent++;
		scope(exit) indent--;
		scope(exit) stdout.writefln("%s%s: getNextFragment.return fragmentStack.length = %s",tabs,__LINE__,fragmentStack.length);
	}
	
	if ( elemNum >= patternElements.length )
		return;

	void push(uint lno = __LINE__)(NfaFragment fragment)
	{
		fragmentStack ~= fragment;
		version( TRACE_NFA ) {
			stdout.writefln("%s%s: push(): OP=%s",tabs,lno,stemToString(fragment.startNode.op));
			stdout.writefln("%s%s:         new size = %s",tabs,lno,fragmentStack.length);
		}
	}
	
	NfaFragment pop(uint lno = __LINE__)()
	{
		if ( fragmentStack.length == 0 )
			throw new Exception(to!string(lno)~": Attempt to pop from an empty stack.");

		auto fragment = fragmentStack[$-1];
		fragmentStack.length -= 1;
		version( TRACE_NFA ) {
			stdout.writefln("%s%s: pop(): OP=%s",tabs,lno,stemToString(fragment.startNode.op));
			stdout.writefln("%s%s:        new size = %s",tabs,lno,fragmentStack.length);
		}
		return fragment;
	}
	
	auto stackSizeAtStart = fragmentStack.length;
	
	auto elem = patternElements[elemNum];
	auto stem = elem & OP_STEM_MASK; // If it isn't an OP, we'll just not use the stem.
	
	elemNum++;
	//alias typeof(elem) T;

	if ( isToken(elem) )
	{
		version( TRACE_NFA ) stdout.writefln("SyntaxElement: %s", elem);
		auto newState = new NfaState(elem, null, null);
		push(NfaFragment(newState, &newState.out1));
	}
	else if ( stem == OP_BEGIN )
	{
		version( TRACE_NFA ) stdout.writeln("OP_BEGIN");
		
		getNextFragment(fragmentStack, patternElements, elemNum);
	
		//auto lhs = pop();
		//auto lhsOp = lhs.startNode.op;
		//push(lhs);
		
		//if ( lhsOp != OP_END ) // Guard against BEGIN-END groups with zero fragments inbetween.
		while(true)
		{
			// We're done constructing the concatenated fragment once the
			//   corresponding OP_END is reached.
			if ( elemNum < patternElements.length &&
			     patternElements[elemNum] == OP_END )
			{
				elemNum++;
				break;
			}
		
			getNextFragment(fragmentStack, patternElements, elemNum);
		
			auto rhs = pop();
			
			if ( fragmentStack.length == 0 )
				throw new Exception("OP_BEGIN does not have a corresponding OP_END.");
	
			auto lhs = pop();
			
			patch(lhs.danglingArrows, rhs.startNode);
			lhs.danglingArrows = rhs.danglingArrows;
			
			push(lhs);
		}
	}
	else if ( stem == OP_END )
	{
		version( TRACE_NFA ) stdout.writeln("OP_END");
	}
	else if ( stem == OP_OR )
	{
		version( TRACE_NFA ) stdout.writeln("OP_OR");
		
		auto lhs = pop();
		
		getNextFragment(fragmentStack, patternElements, elemNum);
		
		if ( fragmentStack.length == 0 )
			throw new Exception("No 2nd argument given for OP_OR.");
		
		auto rhs = pop();
		
		NfaFragment newFrag;
		newFrag.startNode = new NfaState(OP_OR, lhs.startNode, rhs.startNode);
		newFrag.danglingArrows  = lhs.danglingArrows;
		newFrag.danglingArrows ~= rhs.danglingArrows;
		push(newFrag);
	}
	else if ( stem == OP_MAYBE )
	{
		version( TRACE_NFA ) stdout.writeln("OP_MAYBE");
		auto frag = pop();
		auto newState = new NfaState(OP_MAYBE, frag.startNode, null);
		frag.startNode = newState;
		frag.danglingArrows ~= &newState.out2;
		push(frag);
	}
	else if ( stem == OP_REPEAT_STEM )
	{
		version( TRACE_NFA ) stdout.writeln("OP_REPEAT");
		auto minTimes = (elem & OP_REPEAT_MIN_ARGMASK) >> OP_REPEAT_MIN_ARGSHIFT;
		auto maxTimes = (elem & OP_REPEAT_MAX_ARGMASK) >> OP_REPEAT_MAX_ARGSHIFT;
		auto repeatedFragment = pop();
		
		// First part of repetition: minimum repeats.
		NfaFragment minFragment;
		minFragment.startNode = null;
		if ( minTimes > 0 )
			minFragment = genFiniteRepetitionFragment(repeatedFragment, minTimes);
		
		NfaFragment maxFragment;
		if ( maxTimes == OP_ARG_INFINITY )
		{
			// Indefinite repetition.
			auto newState = new NfaState(OP_REPEAT_STEM, repeatedFragment.startNode, null);
			patch(repeatedFragment.danglingArrows, newState);
			maxFragment = NfaFragment(newState, &newState.out2);
		}
		else
		{
			// Finite repetition.
			maxFragment = genFiniteRepetitionFragment(repeatedFragment, maxTimes - minTimes);
		}
		
		// Concatenate the minFragment and maxFragment as necessary.
		NfaFragment newFragment;
		if ( minFragment.startNode != null )
		{
			patch(minFragment.danglingArrows, maxFragment.startNode);
			newFragment.startNode = minFragment.startNode;
			newFragment.danglingArrows = maxFragment.danglingArrows;
		}
		else
			newFragment = maxFragment;
		
		// Put out the result.
		push(newFragment);
	}
	else
		throw new Exception("Operation not implemented.");
	
	// 
	if ( elemNum < patternElements.length &&
	     !isToken(patternElements[elemNum]) &&
	     stemHasLhs(patternElements[elemNum]))
		getNextFragment(fragmentStack, patternElements, elemNum);
}

private NfaFragment genFiniteRepetitionFragment( const NfaFragment repeatedFragment, SyntaxElement nTimes )
{
	
	if ( nTimes == 0 )
	{
		auto newState = new NfaState(OP_NOOP, null, null);
		return NfaFragment(newState, &newState.out1);
	}
	
	auto prevFragment = repeatedFragment.deepCopy();
	for ( int i = 1; i < nTimes; i++ )
	{
		auto newFragment = repeatedFragment.deepCopy();
		patch(prevFragment.danglingArrows, newFragment.startNode);
		newFragment.startNode = prevFragment.startNode;
		prevFragment = newFragment;
	}
	return prevFragment;
}

//============================================================================//
//                        DFA definitions.                                    //
//============================================================================//

struct DfaMove
{
	SyntaxElement  token;
	DfaState*      nextState;
	
	this( SyntaxElement token, DfaState* nextState )
	{
		this.token = token;
		this.nextState = nextState;
	}
	
	int opCmp( ref const DfaMove m ) const
	{
		return .opCmp(this.token, m.token);
	}
}

struct DfaState
{
	// The NFA state tuple that this DFA state comes from.
	// This gives us fast comparisons and the ability to use it as a hash key.
	NfaLabel[] nfaStateTuple;
	
	// This describes which tokens transition the DFA into which next state.
	// This should also be sorted to make matching faster by making it faster
	//   to determine which state to transition into next.
	DfaMove[] moves;
	
	// An integer that uniquely identifies this state within the automaton
	//   it occupies.
	int label = -1;
	
	// Does ending on this node mean that the input is recognized by the DFA?
	bool isFinal = false;
	
	
	private struct DfaToDPrinter
	{
		int depth = 0;
		const(DfaState*)[] visited;
	}
	
	string nfaTupleToIdent()
	{
		string ident = "dfa";
		foreach( nfaLabel; nfaStateTuple )
			ident ~= "_" ~ itoa(nfaLabel);
		return ident;
	}
	
	string toD()
	{
		DfaToDPrinter d2dp;
		d2dp.visited = new DfaState*[0];
		return 
		"bool dfaMatch( SyntaxElement[] input )\n"~
		"{\n"~
		"	if ( input is null || input.length == 0 )\n"~
		"		return false;\n"~
		"\n"~
		"	size_t state = 0;\n"~
		"	size_t pos = 0;\n"~
		"	bool matches = false;\n"~
		"	SyntaxElement token;\n"~
		"	switch(state)\n"~
		"	{\n"~
		toD(d2dp)~
		"\n"~
		"		default: break;\n"~
		"	}\n"~
		"	return matches;\n"~
		"}\n";
	}
	
	string toD(ref DfaToDPrinter d2dp)
	{
		version( TRACE_NFA )
		{
			auto tabs = std.array.replicate("\t",d2dp.depth);
			d2dp.depth++;
			scope(exit) d2dp.depth--;
		}
		
		d2dp.visited ~= &this; //NfaStatePrintingMetadata(&this,label);
		
		string otherStates = "";
		string result =
		"		case "~itoa(label)~": // "~nfaTupleToIdent()~"\n"~
		"			if ( pos >= input.length ) {\n"~
		(isFinal ?
		"				matches = true;\n" : "")~
		"				break;\n"~
		"			}\n"~
		"			token = input[pos++];\n";
		
		int recurse( DfaState* next )
		{
			// First, try to return an already-visited label.
			for ( int i = 0; i < d2dp.visited.length; i++ )
				if ( d2dp.visited[i] is next )
					return d2dp.visited[i].label;
		
			//// Allocate a new node ID and save it so we can return it to the caller.
			//d2dp.curNodeId++;
			//auto idCaptured = d2dp.curNodeId;
			
			// First encounter: generate a function for it.
			otherStates ~= next.toD(d2dp);
			
			return next.label;
		}
		
		foreach( move; moves )
		{
			auto otherNodeLabel = recurse(move.nextState);
			result ~=
		"			if ( token == "~itoa(move.token)~" )\n"~
		"				goto case "~itoa(otherNodeLabel)~";\n";
		}
		
		if ( isFinal )
			result ~=
		"			matches = true;\n";
	
		result ~=
		"			break;\n\n";
		
		return result ~ otherStates;
	}
	
	const hash_t toHash()
	{
		auto bytes = cast(ubyte[]) nfaStateTuple;
		hash_t hash = 5381;
		
		for ( int i = 0; i < bytes.length; i++ )
			hash = ((hash << 5) + hash) + bytes[i];
	
		return hash;
	}
	
	const bool opEquals(ref const DfaState* s)
	{
		return std.algorithm.cmp(this.nfaStateTuple, s.nfaStateTuple) == 0;
	}
	
	const int opCmp(ref const DfaState* s)
	{
		return std.algorithm.cmp(this.nfaStateTuple, s.nfaStateTuple);
	}
}

private void dfaLabelAndIndex( ref DfaState*[] dfaArray, DfaState* startNode )
{
	if ( startNode is null )
		return;
	
	foreach( ref otherNode; dfaArray )
		if ( otherNode is startNode )
			return; // Already visited.
	
	startNode.label = dfaArray.length;
	dfaArray ~= startNode;
	
	foreach ( move; startNode.moves )
		dfaLabelAndIndex(dfaArray, move.nextState);
}

DfaState*[] dfaLabelAndIndex( DfaState* startNode )
{
	auto dfaArray = new DfaState*[0];
	dfaLabelAndIndex(dfaArray, startNode);
	return dfaArray;
}


//============================================================================//
//                        DFA consruction functions.                          //
//============================================================================//

struct NfaMove
{
	SyntaxElement      token;
	const(NfaState)*[] nextStates;
	
	int opCmp( ref const NfaMove m ) const
	{
		return .opCmp(this.token, m.token);
	}
}

bool nfaTuplesMatch( DfaState* s1, DfaState* s2 )
{
	for ( int i = 0; i < s1.nfaStateTuple.length; i++ )
	{
		if ( i > s2.nfaStateTuple.length )
			return false;
		
		if ( s1.nfaStateTuple[i] !is s2.nfaStateTuple[i] )
			return false;
	}
	
	return true;
}

int binarySearch(T)(const T[] arr, const T elem, size_t imin, size_t imax)
{
	while (imax > imin)
	{
		size_t imid = (imin + imax) / 2;
		if (arr[imid] < elem)
			imin = imid + 1;
		else
			imax = imid;
	}
	return imin;
}

int binarySearch(T)( const T[] arr, const T elem )
{
	return binarySearch(arr, elem, 0, arr.length);
}

unittest
{
	assert( binarySearch([1,3,5],0) == 0 );
	assert( binarySearch([1,3,5],1) == 0 );
	assert( binarySearch([1,3,5],2) == 1 );
	assert( binarySearch([1,3,5],3) == 1 );
	assert( binarySearch([1,3,5],4) == 2 );
	assert( binarySearch([1,3,5],5) == 2 );
	assert( binarySearch([1,3,5],6) == 3 );
}

T[] sortedNoDupInsert(T)( T[] arr, T elem )
{
	auto i = binarySearch(arr,elem);
	
	// It's not there, but it would go at the end of the array.  Easy.
	if ( i == arr.length )
	{
		arr ~= elem;
		return arr;
	}
	
	// It's already there, no need to add it.
	if ( arr[i] == elem )
		return arr;
	
	// It's not there, and it belongs somewhere in the middle or beginning.
	arr.length = arr.length + 1;
	for( int j = arr.length-1; j > i; j-- )
		arr[j] = arr[j-1];
	
	arr[i] = elem;
	
	return arr;
}

unittest
{
	assert( sortedNoDupInsert([1,3,5],2) == [1,2,3,5] );
	assert( sortedNoDupInsert([1,3,5],6) == [1,3,5,6] );
	assert( sortedNoDupInsert([1,3,5],3) == [1,3,5] );
}

void addMove( ref NfaMove[SyntaxElement] moves, SyntaxElement t, const NfaState* destination )
{
	if ( destination is null )
		return;
	
	NfaMove move;
	auto movePtr = t in moves;
	if ( movePtr is null )
	{
		// There is no previous move on this token, so let's add one.
		move.token = t;
		move.nextStates = new const(NfaState)*[1];
		move.nextStates[0] = destination;
		moves[t] = move;
	}
	else
	{
		// Add the destination state onto the list of states that the token
		//   causes the NFA to move into.
		movePtr.nextStates ~= destination;
	}
}

NfaMove[] getNfaMoves( const NfaState*[] nfa, const NfaLabel[] startStates )
{
	NfaMove[SyntaxElement] result;
	foreach ( startStateLabel; startStates )
	{
		auto startState = nfa[startStateLabel];
		if ( !isToken(startState.op) )
			continue;
		
		addMove(result, startState.op, startState.out1);
		addMove(result, startState.op, startState.out2);
	}
	return result.values.sort;
}

void epsilonClosureRecurse( const NfaState* startState, ref NfaLabel[] reachableStates )
{
	if ( startState is null )
		return;
	
	NfaLabel label = startState.label;
	auto i = binarySearch(reachableStates, label);
	if ( i < reachableStates.length && reachableStates[i] == label ) // Break cycles.
		return;
	
	reachableStates = sortedNoDupInsert(reachableStates, label);
	if ( !isToken(startState.op) ) // It's an epsilon closure, so things behind tokens are unreachable.
		epsilonClosureFork(startState, reachableStates);
}

/// Same as epsilonClosure below, but done for a single start state.
/// This will do sorted inserts into the reachableStates array and create
///   no duplicates.
void epsilonClosureFork( const NfaState* startState, ref NfaLabel[] reachableStates )
{
	epsilonClosureRecurse(startState.out1, reachableStates);
	epsilonClosureRecurse(startState.out2, reachableStates);
}

/// Returns which states can be reached from the startStates without consuming
///   any tokens at all (that is, by consuming the 'epsilon' token).
NfaLabel[] epsilonClosure( const NfaState*[] startStates )
{
	NfaLabel[] reachableStates;
	foreach ( startState; startStates )
		epsilonClosureRecurse(startState, reachableStates);
	return reachableStates;
}

DfaState*[] toDfa( const NfaState*[] nfa )
{
	scope DfaState*[] unmarkedStates = new DfaState*[1];
	scope DfaState*[NfaLabel[]] states;
	
	DfaState* result = new DfaState();
	result.nfaStateTuple = epsilonClosure(nfa[0..1]);
	NfaLabel labelHack = nfa[0].label; // remove const-ness by copying.
	result.nfaStateTuple = sortedNoDupInsert( result.nfaStateTuple, labelHack );
	result.moves = new DfaMove[0];
	
	states[result.nfaStateTuple.idup] = result;
	unmarkedStates[0] = result;
	
	while ( unmarkedStates.length > 0 )
	{
		auto dfaState = unmarkedStates[$-1];
		unmarkedStates.length = unmarkedStates.length - 1;
		
		// This finds out what tokens the DFA can match to advance, and which
		//   NFA states those tokens would result in.
		auto nfaMoves = getNfaMoves(nfa, dfaState.nfaStateTuple);
		
		// Create a new DFA node for each move (except for ones already made).
		foreach ( nfaMove; nfaMoves )
		{
			// Get all of the NFA states that can be reached by taking this
			//   move and then traversing unlabelled edges.
			auto nfaStateTuple = epsilonClosure(nfaMove.nextStates);
			DfaState* newDfaState;
			
			// See if we've already generated this state.
			auto statePtr = nfaStateTuple in states;
			if ( statePtr == null )
			{
				// It doesn't exist already.
				// Initialize it and add it to the list.
				newDfaState = new DfaState();
				newDfaState.nfaStateTuple = nfaStateTuple;
				newDfaState.moves = new DfaMove[0];
				states[nfaStateTuple.idup] = newDfaState;
				unmarkedStates ~= newDfaState;
			}
			else
				newDfaState = *statePtr; // Use the already-existing one.
			
			// Add an edge in the DFA graph: dfaState->newDfaState
			dfaState.moves = sortedNoDupInsert(
				dfaState.moves, DfaMove(nfaMove.token, newDfaState) );
		}
	}
	
	// Mark the final state(s).
	foreach ( ref dfaState; states.byValue() )
	{
		foreach ( nfaLabel; dfaState.nfaStateTuple )
			if ( nfa[nfaLabel].op == OP_MATCH ) // nfaState.isFinal == true
				dfaState.isFinal = true;
	}
	
	return dfaLabelAndIndex(result);
}


//============================================================================//
//                        Scaffolding.                                        //
//============================================================================//

void matchNodes(A...)( /*AstNode node,*/ A patternElements )
{
	//const nfa = createNfa([patternElements]);
	auto nfa = createNfa([
		1,
		2,
		OP_BEGIN,
			3,
			4,
		OP_END,
		OP_OR,
		OP_BEGIN,
			5,
			6, OP_REPEAT(),
		OP_END,
		7]);
	auto nfaStr = nfa[0].toD();
	//pragma(msg,nfaStr);
	stdout.writeln(nfa[0].toD());
	
	auto dfa = toDfa(nfa);
	stdout.writeln(dfa[0].toD());
	
}

import pegged.development.grammarfunctions;
import pegged.examples.dgrammar;
import pegged.examples.c;

void main()
{
	auto c = checkGrammar(Cgrammar, ReduceFurther.Yes);
	writeln(c);
	foreach(k,v;c)
		if (v != Diagnostic.NoRisk) writeln(k,":",v);
	
	stdout.writefln("Parsing ccode/example.c");
	auto tree = C.TranslationUnit.parse(to!string(std.file.read("ccode/example.c")));
	stdout.writefln("%s",tree.toString());
	/+stdout.writefln("Parsing test.d");
	auto tree = D.Module.parse(to!string(std.file.read("test.d")));
	stdout.writefln("%s",tree.toString());
	stdout.writefln("Parsing main.d");
	tree = D.Module.parse(to!string(std.file.read("main.d")));
	stdout.writefln("%s",tree.toString());
+/
	//trace!"Hello %s!"("world");
	/+matchNodes(
		TOK_A,
		TOK_B,
		TOK_C);
	+/
	/+
	matchNodes(
		TOK_A,
		TOK_B,
		OP_BEGIN,
			TOK_C,
			TOK_C,
		OP_END,
		OP_OR,
		OP_BEGIN,
			TOK_A,
			TOK_B, OP_REPEAT(),
		OP_END,
		TOK_C);
	+/
	
	stdout.writefln("?: %s",dfaMatch([5,4]));
	stdout.writefln("?: %s",dfaMatch([1,2,3,4,7]));
	stdout.writefln("?: %s",dfaMatch([1,2,5,6,7]));
	stdout.writefln("?: %s",dfaMatch([1,2,5,6,6,6,7]));
	stdout.writefln("?: %s",dfaMatch([1,2,5,6,7,6,7]));
	stdout.writefln("?: %s",dfaMatch([1,2,5,6,3,6,7]));
	
	//auto tree = DParse.Module.parse(std.file.read("main.d"));
	//stdout.writefln(tree.toString());
	return;
	matchNodes(
		1,
		2,
		
		OP_BEGIN,
			3,
			4,
		OP_END,
		OP_OR,
		OP_BEGIN,
			5,
			6, OP_REPEAT(),
		OP_END,
		7);
}

bool dfaMatch( SyntaxElement[] input )
{
        if ( input is null || input.length == 0 )
                return false;

        size_t state = 0;
        size_t pos = 0;
        bool matches = false;
        SyntaxElement token;
        switch(state)
        {
                case 0: // dfa_0
                        if ( pos >= input.length ) {
                                break;
                        }
                        token = input[pos++];
                        if ( token == 1 )
                                goto case 1;
                        break;

                case 1: // dfa_1
                        if ( pos >= input.length ) {
                                break;
                        }
                        token = input[pos++];
                        if ( token == 2 )
                                goto case 2;
                        break;

                case 2: // dfa_2_3_7
                        if ( pos >= input.length ) {
                                break;
                        }
                        token = input[pos++];
                        if ( token == 5 )
                                goto case 3;
                        if ( token == 3 )
                                goto case 5;
                        break;

                case 3: // dfa_5_8_9
                        if ( pos >= input.length ) {
                                break;
                        }
                        token = input[pos++];
                        if ( token == 7 )
                                goto case 4;
                        if ( token == 6 )
                                goto case 3;
                        break;

                case 4: // dfa_6
                        if ( pos >= input.length ) {
                                matches = true;
                                break;
                        }
                        token = input[pos++];
                        matches = true;
                        break;

                case 5: // dfa_4
                        if ( pos >= input.length ) {
                                break;
                        }
                        token = input[pos++];
                        if ( token == 4 )
                                goto case 6;
                        break;

                case 6: // dfa_5
                        if ( pos >= input.length ) {
                                break;
                        }
                        token = input[pos++];
                        if ( token == 7 )
                                goto case 4;
                        break;


                default: break;
        }
        return matches;
}


/+
Lower
	while ( boolExpr )
	{
		statements;
	}

Into

	loopAgain:
	if ( !boolExpr )
		goto exitLoop
	statements;
	goto loopAgain
	exitLoop:
+/
/+
void lowerWhileStatement( SyntaxElement* syntaxNode )
{
	auto captures = syntaxNode.matchNodes(
		TOK_WHILE_NODE,
		OP_ENTER_NODE,
			OP_CAPTURE(0),
			OP_BEGIN,
				TOK_EXPRESSION,
			OP_END,
			OP_CAPTURE(1),
			OP_BEGIN,
				TOK_STATEMENT,
			OP_END,
		OP_LEAVE_NODE);
	
	if ( captures is null )
		return;
	
	syntaxNode.replaceWith(
		LabelNode("loopAgain"),
		TOK_IF_STATEMENT,
		OP_INSERT,
		OP_BEGIN,
			TOK_NEGATE,
			OP_INSERT,
			OP_BEGIN,
				captures[0], // Expression
			OP_END,
			GotoStatement("exitLoop"),
		OP_END,
		captures[1], // statements
		GotoStatement("loopAgain"),
		LabelNode("exitLoop")
		);
}
+/

/+
void findConstEscapes( ParseTree* node )
{
	auto captures = recognize![
		AST_FUNCTION_DECL,
		OP_ENTER_NODE,
		OP_BEGIN,
			OP_REPEAT, OP_ANY,
			AST_FUNCTION_PURE_ATTR,
			OP_REPEAT, OP_ANY,
			AST_BLOCK_STATEMENT,
				OP_FLATTEN_NODE,
				OP_BEGIN
					OP_REPEAT, OP_ANY,
					AST_SCOPE,
						OP_CAPTURE_VARIANT("scope");
					OP_REPEAT,
						OP_BEGIN,
							OP_REPEAT, OP_ANY,
							OP_CAPTURE("sideEffect"),
								sideEffectfulExpression(),
						OP_END,
				OP_END,
		OP_END] (node);
	// TODO: what about calls to non-const methods?
	
	auto fscope = captures["scope"].get!(Scope*);
	
	foreach( expr; captures["sideEffect"] )
	{
		auto exprCaptures = recognize![
			getAffectedLValues(expr.metadata.token),
			OP_BEGIN, // TODO: check to make sure it's a variable or something with a symbol.
				OP_CHECK("lookup(fscope, AST_<insert symbol name here>)"),
				// TODO: what if it isn't in fscope?
			OP_END,
	}
}
+/

void fun(T:int)(T a)
{
}

void fun(T)(T a, T b)
{
}

fun(1,2); // What happen?