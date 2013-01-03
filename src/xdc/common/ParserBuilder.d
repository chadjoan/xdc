module xdc.common.ParserBuilder;

import std.array;
import std.conv;
import std.container;
import std.range;
import std.stdio;

/+
Unitary Expression: an expression that, given an input string, has only one 
  possible match (only one match.end is possible).
  PEG rules are unitary expressions.
  Terminals are unitary expressions as well.
  Ex: aa/a on the input "aaa" has only one match: [aa]a

Nonunitary Expression: an expression that, given an input string, has many
  possible matches.
  Regular expression operators are nonunitary expressions.
  Ex: aa|a on the input "aaa" may match [a]aa or [aa]a depending on whether the
    code driving the expression requests 1 or 2 characters.

Both unitary and nonunitary expressions may reside within regular expressions.
Only unitary expressions are allowed in PEGs.
Nonunitary expressions can be converted into unitary expressions by using some
  manner of rule to disambiguate which match to take.  Intuitively, we define
  "longest" and "shortest" rules to accomplish this.
We can thus create unitary expressions with nonunitary subexpressions, and
  gain some of the convenience of regular expressions within more powerful
  constructs like PEGs.

Nonunitary expressions are not reentrant without an explosion of algorithmic
  complexity.  This prevents PEGs from having things like unordered choice:
    A <- b*aB
    B <- (A|b*)
  In this case, the rule called within the unordered choice (the | operator)
  will invoke B again and reenter the choice without first resolving the succuss
  of the first unordered choice entry.  This ambiguity can result in repeated
  backtracking.
  (TODO: is this example good? maybe use a better one that will obviously create
    a lot of backtracking.)

The concatenation of a nonunitary expression and a unitary expression is nonunitary.

PEG elements may not follow nonunitary expressions in concatenation without
  suffering a large penalty in algorithmic complexity.  This arrangement
  requires nonlocal backtracing out of failed matches of the PEG until a place
  on the input is found where the nonunitary expression before it matches and
  the PEG also matches the text ahead of it.  To maintain linear complexity,
  such nonlinear expressions preceding PEGs must be disambiguated with some
  rule like longest-match or shortest-match.

+/

auto min(T, U)( T a, U b )
{
	return a < b ? a : b;
}

/+

TODO: construct RDPs of NFAs.  The NFAs will periodically need to be converted
to DFAs to allow for operations like complementation/intersection.

Once the desired parser is attained, convert it to a PDA with memoization.



X <- "(xxXxxXxxXxx)" / "(xxXxx" BAR ")" / "(xxXxx" BAZ ")"

Bar <- "a" X "+"

Baz <- "a" X "-"

Foo <- Bar / Baz

int[] X_cache;

bool X(string s, int pos)
{
	if ( X_cache[pos] > 0 ) return true;
	if ( X_cache[pos] < 0 ) return false;
	if ( s[pos..pos+13] == "(xxXxxXxxXxx)" )
	{
		X_cache[pos] = 1;
		return true;
	}
	else if ( Bar(s,pos) || Baz(s,pos) )
	{
		X_cache[pos] = 1;
		return true;
	}
	
	X_cache[pos] = -1;
	return false;
}

bool Bar(string s, int pos)
{
	if ( s[pos] != 'a' ) return false;
	if ( !X(s, pos+1)  ) return false;
	if ( s[pos] != '+' ) return false;
	return true;
}

bool Baz(string s, int pos)
{
	if ( s[pos] != 'a' ) return false;
	if ( !X(s, pos+1)  ) return false;
	if ( s[pos] != '-' ) return false;
	return true;
}

bool Foo(string s, int pos)
{
	X_cache = new byte[s.length];
	foreach( ref xres; X_cache ) xres = 0;
	return Bar(s, pos) || Baz(s, pos);
}

Foo("a(xxXxxa(xxXxxXxxXxx)-)-");
+/

/+
alias void* AutomatonLabel;

const int stackSymbolBacktrack = -2;
const int stackSymbolPop  = -1;
const int stackSymbolNull = 0;
const int recurseSymbolNull = 0;

enum TransitionDir
{
	uninitialized,
	forward,
	backward,
}

final class Transition(ElemType)
{
	private alias AutomatonState!ElemType State;

	string          recurseLabel = null;
	
	int             stackSymbolToMatch = stackSymbolNull;
	int             stackSymbolToPush = stackSymbolNull;
	Label           backtrackLabel; /* Used both when pushing/popping a backtrace symbol. */
	bool            complementStackSymbol = false;
	bool            matchAllInputSymbols = true;
	bool            complementInputSymbol = false;
	ElemType         inputSymbolToMatch;
	int             recurseSymbol = recurseSymbolNull;
	
	State           nextState = null;
	TransitionDir   direction = TransitionDir.uninitialized;
	
	@property bool matchAllStackSymbols() const 
	{
		return (stackSymbolToMatch == stackSymbolNull);
	}
	
	@property bool useRecurseSymbol() const
	{
		return (recurseSymbol != recurseSymbolNull);
	}
	
	int opCmp( ref const Transition t ) const
	{
		return .opCmp(this.inputSymbolToMatch, t.inputSymbolToMatch);
	}
	
	bool attempt(R)( size_t* pos, R input ) if ( isRandomAccessRange!(R) )
	{
		auto c = input[*pos];
		if ( useRecurseSymbol )
		{
		}
		else if (
			(matchAllInputSymbols || c == inputSymbolToMatch) && 
			(matchAllStackSymbols || stackSymbolToMatch == symbolStack.front) &&
			(!useRecurseSymbol) )
		{
			if ( stackSymbolToPush == stackSymbolPop )
				symbolStack.pop();
			else if ( stackSymbolToPush != stackSymbolNull )
				symbolStack.push(stackSymbolToPush);
			
			(*pos)++;
			
			return true;
		}
		else
			return false;
	}
	
	@property bool isFiniteTransition() const
	{
		return (useInputSymbol && !useStackSymbol && !useRecurseSymbol);
	}
}

final class AutomatonState(SymbolType)
{
	private alias Transition!ElemType Transition;
	
	// This is usually the NFA state tuple that this DFA state comes from.
	// This gives us fast comparisons and the ability to use it as a hash key.
	AutomatonLabel[] nfaStateTuple;
	
	// This describes which symbols transition the automaton into which next 
	//   state.
	// This should also be sorted to make matching faster by making it faster
	//   to determine which state to transition into next.
	Transition[] transitions;
	
	// An integer that uniquely identifies this state within the automaton
	//   it occupies.
	@property AutomatonLabel label() const
	{
		return (AutomatonLabel)(void*)this;
	}
	
	// Does ending on this node mean that the input is recognized by the 
	//   automaton?
	bool isFinal = false;
	
	this()
	{
		nfaStateTuple = new AutomatonLabel[0];
		transitions = new Transition[0];
	}
	
	void addTransition( Transition t )
	{
		transitions ~= t;
	}
}

struct AutomatonFragment(ElemType)
{
	private alias Transition!ElemType     Transition;
	private alias AutomatonFragment!ElemType Fragment;
	private alias AutomatonState!ElemType State;
	
	State        startNode;
	Transition[] danglingArrows;
	
	Fragment toDfa()
	{
		// Create a final node to tie all of the dangling arrows into.
		// This is necessary for performing the NFA->DFA conversion, as it
		//   allows the DFA to use the final state in its constructions.
		// We will later remove final states from the DFA and make their 
		//   arrows/transitions be the new danglingArrows list.
		auto acceptState = new State();
		acceptState.isFinal = true;
		
		foreach( ref transition; danglingArrows )
			transition.nextState = acceptState;
		
		// Create another final node that things travel to when they aren't
		//   recognized.  This will turn into some important nodes in the DFA
		//   because they are accepting states under complementation.
		auto rejectState = new State();
		// TODO: walk all nodes and create complementary transitions going to
		//   the reject state.  It may also need an arrow going back into itself.
		//   See: http://www.cs.odu.edu/~toida/nerzic/390teched/regular/fa/complement.html
		
		
	}
}

template AutomatonFuncs(ElemType)
{
	private alias Transition!ElemType        Transition;
	private alias AutomatonFragment!ElemType Fragment;
	private alias AutomatonState!ElemType    State;
	
	private void epsilonClosureRecurse( const Transition transition, ref State[Label] reachableStates )
	{
		if ( transition is null )
			return;
		
		// It's an epsilon closure, so non-epsilon transitions cannot be taken.
		// Only transitions that require no symbol consumption are allowed.
		if ( transition.isEpsilon )
			epsilonClosureFork(startState, reachableStates);
	}

	// Same as epsilonClosure below, but done for a single start state.
	private void epsilonClosureFork( const State startState, ref State[Label] reachableStates )
	{
		if ( startState is null )
			return;
		
		Label label = startState.label;
		if ( label in reachableStates )
			return; // Break cycles.
		
		reachableStates[label] = startState;

		foreach( transition; startState.transitions )
			epsilonClosureRecurse( transition, reachableStates );
	}

	/// Returns which states can be reached from the startStates without
	///   consuming any tokens at all (that is, by consuming the 'epsilon' token).
	pure State[Label] epsilonClosure( const State[] startStates )
	{
		assert(startStates !is null);
		State[Label] reachableStates;
		foreach ( startState; startStates )
			epsilonClosureFork(startState, reachableStates);
		return reachableStates;
	}
	
	pure Transition newEpsilonTransition()
	{
		return new Transition();
	}
	
	pure Transition newEpsilonTo( const State state )
	{
		auto trans = newEpsilonTransition();
		trans.nextState = state;
		return trans;
	}
	
	pure Fragment newEmptyFragment()
	{
		Fragment result = new Fragment();
		result.startState = new State();
		result.startState.addTransition(newEpsilonTransition());
		return result;
	}
}
+/

private struct OpTypeTable
{
	string[] enumNames;
	string[] toStringContents;
	
	void initialize()
	{
		if ( enumNames !is null )
			return;
		
		enumNames = new string[0];
		toStringContents = new string[0];
	}
	
	void define( string enumName, string toStringContent )
	{
		initialize();
		
		enumNames ~= enumName;
		toStringContents ~= toStringContent;
	}
	
	void define( string enumName )
	{
		return define(enumName, enumName);
	}
	
	string emitEnum() const
	{
		string result = "";
		
		result ~= "enum OpType\n{\n";
		foreach( name; enumNames )
			result ~= "\t" ~ name ~ ",\n";
		result ~= "}\n";
		
		return result;
	}
	
	
	string emitToStringFunc() const
	{
		string result = "";
		
		result ~= "string opTypeToString( OpType t )\n{\n";
		result ~= "\tfinal switch( t )\n\t{\n";

		for ( int i = 0; i < enumNames.length; i++ )
			result ~= "\t\tcase OpType." ~ enumNames[i] ~ 
				": return \"" ~ toStringContents[i] ~ "\";\n";

		result ~= "\t}\n";
		result ~= "\tassert(0,\"Attempt to toString an invalid OpType.\");\n";
		result ~= "}\n";
		
		return result;
	}
}

private OpTypeTable defineOpTypes()
{
	OpTypeTable t;
	
	t.define("epsilon"          );
	t.define("literal"          );
	t.define("sequence"         );
	t.define("orderedChoice"    );
	t.define("unorderedChoice"  );
	t.define("intersection"     );
	t.define("maybe"            );
	t.define("complement"       );
	t.define("negLookAhead"     );
	t.define("posLookAhead"     );
	t.define("lazyRepeat"       );
	t.define("greedyRepeat"     );
	t.define("fullRepeat"       );
	t.define("defineRule"       );
	t.define("matchRule"        );
	//t.define("dfaNode"); ?? has all "dfaTransition" children.
	//t.define("dfaTransition"); child[0] == the GrammarNode that must match. child[1] == the next state to move into.
	
	return t;
}

const opTypeTable = defineOpTypes();
mixin(opTypeTable.emitEnum());
mixin(opTypeTable.emitToStringFunc());

final class GrammarNode(ElemType)
{
	alias typeof(this) Node;
	alias Node[] ChildList;
	
	OpType type;
	
	union
	{
		private ChildList  m_children; /* When type != OpType.literal */
		private ElemType[] m_values;   /* When type == OpType.literal */
	}
	
	pure ref @property auto children()
	{
		assert( type != OpType.literal );
		return m_children;
	}
	
	ref @property auto children( ChildList newb )
	{
		assert( type != OpType.literal );
		return m_children = newb;
	}
	
	pure ref @property auto values()
	{
		assert( type == OpType.literal );
		return m_values;
	}
	
	ref @property auto values( ElemType[] newb )
	{
		assert( type == OpType.literal );
		return m_values;
	}
	
	void insertBack( Node child )
	{
		assert( type != OpType.literal );
		m_children ~= child;
	}
	
	void insertBack( ElemType value )
	{
		assert( type == OpType.literal );
		m_values ~= value;
	}
	
	this() {}
	
	/* Used for non-literal construction. */
	this(OpType type)
	{
		assert(type != OpType.literal);
		this.type = type;
		this.children = new Node[0];
	}
	
	this(size_t nElements)
	{
		this.type = OpType.literal;
		this.m_values = new ElemType[nElements];
	}
	
	this(ElemType elem )
	{
		this.type = OpType.literal;
		this.m_values = new ElemType[1];
		this.m_values[0] = elem;
	}
	
	static Node epsilon()
	{
		auto n = new Node();
		n.type = OpType.epsilon;
		return n;
	}
	
	string toString( uint depth ) const
	{
		string result = std.array.replicate(" ", min(depth*2,256)) ~ opTypeToString(type);
		if ( type == OpType.literal )
			result ~= " " ~ to!string(m_values);
		else
			foreach( child; m_children )
				result ~= "\n" ~ child.toString(depth+1);
		
		return result;
	}
	
	string toString()
	{
		return toString(0);
	}
	
	public struct DCode
	{
		string code;
		string entryFuncName;
	}
	
	private string dCodeEpsilon(ref string suffix, ref string[int] symbolsById)
	{
		return
			"\t\t/* Epsilon */\n"~
			"\t\treturn Match.success(inputRange, cursor, cursor);\n";
	}
	
	private string dCodeLiteral(ref string suffix, ref string[int] symbolsById)
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
	
	private string dCodeSequence(ref string suffix, ref string[int] symbolsById)
	{
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
	
	private string dCodeOrderedChoice(ref string suffix, ref string[int] symbolsById)
	{
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
	
	private string dCodeNegLookAhead(ref string suffix, ref string[int] symbolsById)
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
	
	private string dCodePosLookAhead(ref string suffix, ref string[int] symbolsById)
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
	
	private string dCodeFullRepeat(ref string suffix, ref string[int] symbolsById)
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
	
	DCode toDCode(ref string[int] symbolsById)
	{
		DCode result;
		
		int thisFuncId = symbolsById.length;
		result.entryFuncName = "n"~std.conv.to!string(thisFuncId);
		symbolsById[thisFuncId] = result.entryFuncName;
		
		result.code = "";
		string suffix = "";
		
		const string funcParams =
			"( const "~ElemType.stringof~"[] inputRange, size_t cursor, size_t ubound )";
		
		string funcHeader = 
		
		result.code ~=
			"\tstatic Match "~result.entryFuncName ~ funcParams ~ "\n"~
			"\t{\n"~
			"\t\twritefln(\""~result.entryFuncName~"(%s,%s,%s)\",inputRange,cursor,ubound);\n";
			

		final switch( type )
		{
			case OpType.epsilon:         result.code ~= dCodeEpsilon(suffix,symbolsById); break;
			case OpType.literal:         result.code ~= dCodeLiteral(suffix,symbolsById); break;
			case OpType.sequence:        result.code ~= dCodeSequence(suffix,symbolsById); break;
			case OpType.orderedChoice:   result.code ~= dCodeOrderedChoice(suffix,symbolsById); break;
			case OpType.negLookAhead:    result.code ~= dCodeNegLookAhead(suffix,symbolsById); break;
			case OpType.posLookAhead:    result.code ~= dCodePosLookAhead(suffix,symbolsById); break;
			case OpType.fullRepeat:      result.code ~= dCodeFullRepeat(suffix,symbolsById); break;
			case OpType.matchRule:       throw new Exception("Currently unimplemented.  Needs more node polymorphism?");
			case OpType.intersection:    throw new Exception("Intersection is currently unimplemented.  It requires some NFA/DFA work.");
			case OpType.unorderedChoice: throw new Exception("Unordered choice is currently unimplemented.  It requires some NFA/DFA work.");
			case OpType.complement:      throw new Exception("Complement is currently unimplemented.  It requires some NFA/DFA work.");
			case OpType.lazyRepeat:      throw new Exception("Lazy Repetition is currently unimplemented.  It requires some NFA/DFA work.");
			case OpType.greedyRepeat:    throw new Exception("Greedy Repetition is currently unimplemented.  It requires some NFA/DFA work.");
			case OpType.defineRule:      throw new Exception("This is currently not a valid node.");
			case OpType.maybe:           assert(0, "'maybe' expressions should always be lowered into choice expressions before a parser is emitted.");
		}
		
		result.code ~=
			"\t}\n"~
			"\n"~suffix;

		return result;
	}
	
	DCode toDCode()
	{
		string[int] symbolsById;
		return toDCode(symbolsById);
	}
	
	pure Node deepCopy() const
	{
		Node result = new Node();
		result.type = this.type;
		if ( type == OpType.literal )
			result.m_values = this.m_values.dup;
		else
		{
			result.m_children = new Node[this.m_children.length];
			foreach( i, child; this.m_children )
				result.m_children[i] = this.m_children[i].deepCopy();
		}
		return result;
	}
}

struct MatchT(ElemType)
{
	alias typeof(this) Match;

	bool successful;
	const(ElemType)[][] matches;
	
	const(ElemType)[] input;
	size_t begin, end;
	
	static Match success(const ElemType[] input, size_t begin, size_t end)
	{
		Match m;
		m.successful = true;
		m.matches = new const(ElemType)[][1];
		m.matches[0] = input[begin..end]; // TODO: have a way to be more complex.
		m.input = input;
		m.begin = begin;
		m.end = end;
		return m;
	}
	
	pure static Match failure(const ElemType[] input)
	{
		Match m;
		m.successful = false;
		m.matches = null;
		m.input = input;
		m.begin = 0;
		m.end = 0;
		return m;
	}
}

/+
// Just sketching what a generated parser might look like.
final class Parser(ElemType)
{
	alias Match!ElemType Match;
	
	Match foo(const ElemType[] inputRange, size_t cursor, size_t ubound)
	{
		/* Sequence */
		auto m1 = bar(inputRange,cursor,ubound);
		if ( !m1.successful )
			return Match.failure(inputRange);

		auto m2 = baz(inputRange,m1.end,ubound);
		if ( !m2.successful )
			return Match.failure(inputRange);
		
		return Match.success(inputRange, m1.begin, m2.end); /* Success. */
	}
	
	Match foo(const ElemType[] inputRange, size_t cursor, size_t ubound)
	{
		/* Intersection */
		auto m1 = bar(text,cursor,limit);
		if ( !m1.successful )
			return Match.failure(inputRange);
		
		auto m2 = baz(text,cursor,m1);
		if ( !m2.successful )
			return Match.failure(inputRange);
		
		auto m3 = qux(text,cursor,m2);
		if ( !m3.successful )
			return Match.failure(inputRange);
		
		if ( m1.end == m2.end && m2.end == m3.end )
			return Match.success(inputRange, m0.begin, m0.end);
		else
			return Match.failure(inputRange);
	}
	
	Match foo(const ElemType[] inputRange, size_t cursor, size_t ubound)
	{
		/* Ordered Choice */
		size_t p1 = bar(text,cursor,limit);
		if ( p1 != cursor )
			return p1; /* Success. */

		size_t p2 = baz(text,cursor,limit);
		if ( p2 != cursor )
			return p2; /* Success. */
		
		return cursor; /* Fail. */
	}
	
	Match foo(const ElemType[] inputRange, size_t cursor, size_t ubound)
	{
		/* Shortest Choice */
		size_t p1 = bar(text,cursor,limit);
		size_t p2 = baz(text,cursor,limit);
		
		if ( p1 == cursor )
			return p2;
		if ( p2 == cursor )
			return p1;
		
		return min(p1,p2);
	}
	
	Match foo(const ElemType[] inputRange, size_t cursor, size_t ubound)
	{
		/* Longest Choice */
		size_t p1 = bar(text,cursor,limit);
		size_t p2 = baz(text,cursor,limit);
		
		if ( p1 == cursor )
			return p2;
		if ( p2 == cursor )
			return p1;
		
		return max(p1,p2);
	}
	
	Match foo(const ElemType[] inputRange, size_t cursor, size_t ubound)
	{
		/* Maybe */
		auto m1 = bar(inputRange,cursor,ubound);
		if ( m1.successful )
			return Match.success(inputRange, m1.begin, m1.end);
		
		return Match.failure(inputRange);

	}
	
	Match foo(const ElemType[] inputRange, size_t cursor, size_t ubound)
	{
		/* Repetition */
		size_t newCursor = cursor;
		while ( true )
		{
			auto m0 = bar(inputRange, newCursor, ubound);
			if ( !m0.successful )
				break;
			
			newCursor = m0.end;
		}
		
		return Match.success(inputRange, cursor, newCursor);
	}
	
	Match foo(const ElemType[] inputRange, size_t cursor, size_t ubound)
	{
		/* Complement */
		auto m1 = bar(inputRange,cursor,ubound);
		if ( m1.successful )
			return Match.success(inputRange, m1.begin, m1.end);
		
		return Match.failure(inputRange);

	}
	
	/+
	(ab*a/aba*)c
	abaa
	[aba]ac !
	[abaac]
	+/
}
+/

final class ParserBuilder(ElemType)
{
	/+
	private alias Transition!ElemType        Transition;
	private alias AutomatonFragment!ElemType Fragment;
	private alias AutomatonState!ElemType    State;
	+/
	private alias GrammarNode!ElemType       Node;
	
	bool delayNecessaryLowerings = false;
	
	//private SList!OpType operatorStack;
	//private SList!SList!Node operandStack;
	private SList!(Node) parents;
	private Node parent = null;
	private Node root = null;
	
	this()
	{
		initialize();
	}
	
	void initialize()
	{
		parents = make!(SList!(Node))(cast(Node[])[]);
		
		// TODO: Maybe this should be OpType.define with a name of "opCall"
		root = new Node(OpType.sequence);
		parent = root;
	}
	
	private void pushOp(OpType op)
	{
		assert(op != OpType.literal);
		parents.insertFront(parent);
		parent = new Node(op);
	}
	
	/** Sequencing: Equivalent to the regex operation (ab). */
	void pushSequence()         { pushOp(OpType.sequence); }
	
	/** Alternation: Equivalent to the PEG operation (a/b). */
	void pushOrderedChoice()    { pushOp(OpType.orderedChoice); }
	
	/** Alternation: Equivalent to the regex operation (a|b). */
	void pushUnorderedChoice()  { pushOp(OpType.unorderedChoice); }
	
	/** 
Intersection: An operation that only succeeds if all of its operands succeed.

Currently unimplemented.

Examples:
--------------------
// Example of two broad parsers being narrowed by OpIntersection:
auto pb1 = new ParserBuilder!char;
pb1.pushIntersection();
	pb1.pushUnorderedChoice();
		pb1.literal('a');
		pb1.literal('b');
	pb1.pop();
	pb1.pushUnorderedChoice();
		pb1.literal('b');
		pb1.literal('c');
	pb1.pop();
pb1.pop();
auto p1 = pb1.toParser();
assert(!p1.parse("a"));
assert(p1.parse("b"));
assert(!p1.parse("c"));

// Example of a parser that never matches anything:
auto pb2 = new ParserBuilder!char;
pb2.pushIntersection();
	pb2.literal('a');
	pb2.literal('b');
pb2.pop();
auto p2 = pb2.toParser();
assert(!p2.parse("a"));
assert(!p2.parse("b"));
-------------------- 
	*/
	void pushIntersection()   { pushOp(OpType.intersection); }
	
	/**
	Equivalent to the regex operation (a?). 
	
	Since this is a unary operation, if more than one operand is given, then the
	operands are placed in a sequence that will then be operated on.
	*/
	void pushMaybe() { pushOp(OpType.maybe); }
	
	/**
	Negates its operand.
	
	Since this is a unary operation, if more than one operand is given, then the
	operands are placed in a sequence that will then be operated on.
	*/
	void pushComplement()   { pushOp(OpType.complement); }
	
	/**
	Equivalent to the regex operation (a*?).
	
	Since this is a unary operation, if more than one operand is given, then the
	operands are placed in a sequence that will then be operated on.
	*/
	void pushLazyRepeat() { pushOp(OpType.lazyRepeat); }
	
	/**
	Equivalent to the regex operation (a*).
	
	Since this is a unary operation, if more than one operand is given, then the
	operands are placed in a sequence that will then be operated on.
	*/
	void pushGreedyRepeat() { pushOp(OpType.greedyRepeat); }
	
	/**
	Equivalent to the PEG exression (a*).
	
	It is distinct from greedy repetition in that it will consume all available
	input that matches the operand repeated, even if this makes expressions
	later in sequence fail to match globally when they would have otherwise
	succeeded if repitition terminated earlier.  As an example of this
	difference, consider that the regex a*a would match the string "aaa" whereas
	the PEG a*a would not match "aaa".  The PEG would match all three a's with
	the a* portion and then fail because there is no text left with which to
	match the last 'a' in the expression.
	
	Since this is a unary operation, if more than one operand is given, then the
	operands are placed in a sequence that will then be operated on.
	*/
	void pushFullRepeat() { pushOp(OpType.fullRepeat); }
	
	/** Terminates a list of operands for an operator given by pushOpName(). */
	void pop()
	{
		// TODO:
		// Lower
		//   pb.pushMaybe(); // Some unary operator.
		//       pb.literal('a');
		//       pb.literal('b');
		//   pb.pop();
		// into
		//   pb.pushMaybe(); // Some unary operator.
		//       pb.pushSequence(); // Intuitive n-ary operator that returns unary result.
		//           pb.literal('a');
		//           pb.literal('b');
		//       pb.pop();
		//   pb.pop();
		//
		
		auto temp = parent;
		
		parent = parents.removeAny();
		
		if ( !delayNecessaryLowerings )
			temp = necessaryLowerings(temp);

		parent.insertBack(temp);
	}
	
	void literal( ElemType elem )
	{
		parent.insertBack(new Node(elem));
	}
	
	void compose( const ParserBuilder pb )
	{
		if ( pb is this )
			throw new Exception("Adding a parser to itself is not supported."
				~"  This probably wouldn't do what's expected anyways.");
		parent.insertBack(pb.root.deepCopy());
	}
	
	unittest
	{
		auto pba = new ParserBuilder!char();
		pba.pushSequence();
			pba.pushUnorderedChoice();
				pba.literal('x');
				pba.literal('y');
			pba.pop();
		pba.pop();
		
		Node a1 = pba.root; // Implicit sequence
		Node a2 = a1.children[0]; // pushOpSequence
		Node a3 = a2.children[0]; // pushOpUnorderedChoice
		Node a4 = a3.children[0]; // x
		Node a5 = a3.children[1]; // y
		
		auto pbb = new ParserBuilder!char();
		pbb.compose(pba);
		
		// pbb.root is it's own implicit opSequence.
		Node b1 = pbb.root.children[0]; // pba's former implicit opSequence (copy of).
		Node b2 = b1.children[0]; // copy of pba.pushOpSequence
		Node b3 = b2.children[0]; // copy of pba.pushOpUnorderedChoice
		Node b4 = b3.children[0]; // copy of pba.literal('x')
		Node b5 = b3.children[1]; // copy of pba.literal('y')
		
		assert( b1.type == OpType.sequence );
		assert( b2.type == OpType.sequence );
		assert( b3.type == OpType.unorderedChoice );
		assert( b4.type == OpType.literal );
		assert( b5.type == OpType.literal );
		
		assert( a1 !is b1 );
		assert( a2 !is b2 );
		assert( a3 !is b3 );
		assert( a4 !is b4 );
		assert( a5 !is b5 );
	}
	
	private static Node coalesceUnaryArgs( Node n )
	{
		// TODO:
		// if ( n.isUnary() )
		//     new Node ... etc
		return n;
	}
	
	private static Node lowerMaybeIntoChoice( Node n )
	{
		if ( n.type == OpType.maybe )
		{
			n.type = OpType.orderedChoice;
			n.insertBack(Node.epsilon());
		}
		return n;
	}
	
	private static Node necessaryLowerings( Node n )
	{
		n = coalesceUnaryArgs(n); // Must go before unary ops get lowered into other things.
		n = lowerMaybeIntoChoice(n);
		return n;
	}
	
	private static Node flattenLiterals( Node n )
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
		
		auto newNode = new Node(elemCount);
		size_t i = 0;
		
		ElemType[] newValues = newNode.values;
		foreach( child; n.children )
			foreach ( val; child.values )
				newValues[i++] = val;
		newNode.values = newValues;
	
		return newNode;
	}
	
	unittest
	{
		auto n = new GrammarNode!char(OpType.sequence);
		n.insertBack(new GrammarNode!char('a'));
		n.insertBack(new GrammarNode!char('b'));
		n.insertBack(new GrammarNode!char('c'));
		n = flattenLiterals(n);
		assert( n.type == OpType.literal );
		assert( n.values[0] == 'a' );
		assert( n.values[1] == 'b' );
		assert( n.values[2] == 'c' );
	}

	string toString()
	{
		return root.toString();
	}
	
	string toDCode(string name)
	{
		assert(name != null);

		// TODO: eliminateNullaryExpressions(root);
		
		auto guts = root.toDCode();
		
		string result =
			"struct "~name~"\n"~
			"{\n"~
			"\talias MatchT!"~ElemType.stringof~" Match;\n"~
			"\n"~
			guts.code~
			"}\n";
		
		return result;
	}

}


string makeParser()
{
	auto builder = new ParserBuilder!char;
	builder.pushSequence();
		builder.literal('x');
		builder.pushMaybe();
			builder.literal('y');
		builder.pop();
	builder.pop();
	return builder.toDCode("YoDawg");
}

const foo = makeParser();

pragma(msg, foo);

mixin(foo);


void main()
{
	auto builder = new ParserBuilder!char;
	builder.pushSequence();
		builder.literal('x');
		builder.pushMaybe();
			builder.literal('y');
		builder.pop();
	builder.pop();
	writefln(builder.toString());
	writefln("");
	
	auto m = YoDawg.n0("x",0,1);
	writefln("%s",m.successful);
	m = YoDawg.n0("xy",0,2);
	writefln("%s",m.successful);
	m = YoDawg.n0("xyz",0,3);
	writefln("%s",m.successful);
	m = YoDawg.n0("q",0,1);
	writefln("%s",m.successful);
	m = YoDawg.n0("",0,0);
	writefln("%s",m.successful);
	//writefln("Now then, let's do this.\n");
	//writeln(foo);
}



/+
	private Fragment assembleSeq( SList!Fragment operands )
	{
		return reduce!assembleSeq( operands );
	}
	
	Fragment assembleSeq( inout Fragment a, inout Fragment b )
	{
		auto result = new Fragment();
		result.startState = a.startState;
		foreach( ref transition; a.danglingArrows )
		{
			transition.nextState = b.startState;
			transition.direction = TransitionDir.forward;
		}
		result.danglingArrows = b.danglingArrows;
		return result;
	}
	
	private Fragment assembleOr( SList!Fragment operands )
	{
		return reduce!assembleOr( operands );
	}
	
	string          recurseLabel = null;
	
	int             stackSymbolToMatch = stackSymbolNull;
	int             stackSymbolToPush = stackSymbolNull;
	bool            useInputSymbol = false;
	SymbolT         inputSymbolToMatch;
	int             recurseSymbol = recurseSymbolNull;
	
	State           nextState = null;
	TransitionDir   direction = TransitionDir.uninitialized;
	
	
	private Fragment assembleUnorderedChoice( inout Fragment a, inout Fragment b )
	{
		auto result = new Fragment();
		result.startState = new State();
		foreach ( frag; operands )
		{
			auto regularFrag = frag.toRegularFragment();
			if ( regularFrag is null )
				throw new Exception("Non-regular expressions cannot appear within unordered choice.");
			
			result.startState.addTransition(newEpsilonTo(regularFrag.startState));
			result.danglingArrows ~= regularFrag.danglingArrows;
		}
		return result;
	}
	
	// Complementation distributes over ordered choice in regular grammars:
	// Given (a/b) == (a|(^a&b))
	// Then ^(a/b) == ^(a|(^a&b)) == (^a|^(^a&b)) == (^a|(a&^b)) == (^a/^b)
	
	// The working conjecture is that (uv/xy)c == (uv|(^(uv)&xy)c
	//   (or, by De Morgan's law: (uv/xy)c == (uv|(^(uv|^(xy)))c )
	// It makes some amount of sense: xy is only chosen if uv is never chosen,
	//   therefore that branch of the NFA must recognize strings that are uv
	//   but not xy.  Put another way: when matching uv, ignore any xy because
	//   any string matching xy would have taken the other path.
	// More complex expressions expand like so:
	//   (a/b/c)x == (a|(^a&b)|(^(^a&b)&c))x
	//   (a/b/c/d)x == (a|(^a&b)|(^(^a&b)&c)|(^(^(^a&b)&c)&d))x
	// Let's use that for now with operands that are regular.
	// operands including non-regular elements will need different treatment.
	private Fragment assembleOrderedChoice( SList!Fragment operands )
	{
		A <- (x B / x C) z D
		((x B) | (^(x B) & (x C))) z D
	
	
	
		A <- x B x C x / x
		B <- A C / q
		C <- A B / p
		
		derive!
		B <- A (A B / p) q
		B <- A (A B q / pq)
		B <- A (A A (A B q / pq) q / pq)
		B <- A (A A (A B qq / pqq) / pq)
		B <- A (A A (A B qq / pqq / pq))
		B <- A+ (q+ / pq+)
		C <- A B / p
		C <- A A+ 
		
		A <- x (A A)** x A (A A)** x / x
		
		
    Term     < Factor (Add / Sub)*
    Add      < "+" Factor
    Sub      < "-" Factor
    Factor   < Primary (Mul / Div)*
    Mul      < "*" Primary
    Div      < "/" Primary
    Primary  < Parens / Neg / Number / Variable
    Parens   < :"(" Term :")"
    Neg      < "-" Primary
    Number   < ~([0-9]+)
    Variable <- identifier
    
		
		Term < (Primary (Mul / Div)*) (Add / Sub)*
		Term < (Primary (Mul / Div)*) ("+" Factor / "-" Factor)*
		Term < (Primary (Mul / Div)*) ("+" (Primary (Mul / Div)*) / "-" (Primary (Mul / Div)*))*
		Term < (Primary ("*" Primary / "/" Primary)*) ("+" (Primary ("*" Primary / "/" Primary)*) / "-" (Primary ("*" Primary / "/" Primary)*))*
		
		Primary  < Parens / Neg / Number / Variable
		Primary  < :"(" Term :")" / "-" Primary / ~([0-9]+) / identifier
		
		
		Term < ((Parens / Neg / Number / Variable) ("*" (Parens / Neg / Number / Variable) / "/" (Parens / Neg / Number / Variable))*) ("+" ((Parens / Neg / Number / Variable) ("*" (Parens / Neg / Number / Variable) / "/" (Parens / Neg / Number / Variable))*) / "-" ((Parens / Neg / Number / Variable) ("*" (Parens / Neg / Number / Variable) / "/" (Parens / Neg / Number / Variable))*))*
		Term < ((:"(" Term :")" / "-" Primary / Number / Variable) ("*" (Parens / Neg / Number / Variable) / "/" (Parens / Neg / Number / Variable))*) ("+" ((Parens / Neg / Number / Variable) ("*" (Parens / Neg / Number / Variable) / "/" (Parens / Neg / Number / Variable))*) / "-" ((Parens / Neg / Number / Variable) ("*" (Parens / Neg / Number / Variable) / "/" (Parens / Neg / Number / Variable))*))*
		
		
		Term < (Primary ("*" Primary / "/" Primary)*) ("+" (Primary ("*" Primary / "/" Primary)*) / "-" (Primary ("*" Primary / "/" Primary)*))*
		Primary  < :"(" Term :")" / "-" Primary / ~([0-9]+) / identifier
		
		
		
		rpeg <- "long expression #1" foo / "long expression #2" bar
		foo <- nontrivial "x"
		bar <- nontrivial "y"
		nontrivial <- "ooga booga"
		
		rpeg <- "long expression #1" foo / "long expression #2" bar
		foo <- "ooga booga" "x"
		bar <- "ooga booga" "y"
		
		q <- a{0,30} a{30}
		
		
		p** a == ???
		p** a == (p p** / e0) a == (p p** | ^(p p**)&e0) a == (p p** | e0) a == 
		  (p (p p** | e0) | e0) == ((p p p** | p) | e0) == (p p p** | p | e0) == ...
		
		p* == (p p* | e0)
		
		a** a == ???
		a** a == (a a** / e0) a == A <- a A / e0, B <- A a
		a* a == a+ (regular expressions)
		
		
		B <- A / 0 / 1 / e0
		A <- 0 B 0 / 1 B 1
		
		0110
		
		000010000
	}
	
	private Fragment assembleAnd( SList!Fragment operands )
	{
		
	}
+/



/+
	/** Returns the unoptimized automaton that is being built by this
	ParserBuilder object. */
	@property automaton
	
// Foo <- 'x' Bar?
// Bar <- ('ab'|'ac')|('q'+)|(Foo)
// (Bar) -> savedNfa3
builder.initialize();
builder.define!"Foo"();
	builder.push!"seq"();
		builder.operand('x');
		builder.push!("maybe");
			builder.call!("Bar");
		builder.pop();
	builder.pop();
builder.pop();
builder.define!"Bar"();
	builder.push!"or"();
		builder.operand(savedNfa1);
		builder.operand(savedNfa2);
		builder.call!("Foo");
	builder.pop();
builder.pop();
builder.call!("Bar"); // This bit defines the start/end points for the grammar.

auto savedNfa3 = builder.toNfa();

// Advanced stuff:
// ('ab'|'ac')&('q'+)
builder.initialize();
builder.push!("and");
	builder.operand(savedNfa1);
	builder.operand(savedNfa2);
builder.pop();
+/