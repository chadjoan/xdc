module xdc.common.ParserBuilder;

import std.array;
import std.conv;
import std.container;
import std.range;
import std.stdio;


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
		for ( int i = 0; i < enumNames.length; i++ )
			result ~= "\t" ~ enumNames[i] ~ ",\n";
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
	
	t.define("literal"        );
	t.define("sequence"       );
	t.define("orderedChoice"  );
	t.define("unorderedChoice");
	t.define("shortestChoice" );
	t.define("longestChoice"  );
	t.define("intersection"   );
	t.define("maybe"          );
	t.define("complement"     );
	t.define("lazyRepeat"     );
	t.define("greedyRepeat"   );
	t.define("fullRepeat"     );
	t.define("defineRule"     );
	t.define("matchRule"      );
	//t.define("dfaNode"); ?? has all "dfaTransition" children.
	//t.define("dfaTransition"); child[0] == the GrammarNode that must match. child[1] == the next state to move into.
	
	return t;
}

const opTypeTable = defineOpTypes();
mixin(opTypeTable.emitEnum());
mixin(opTypeTable.emitToStringFunc());

struct GrammarNode(ElemType)
{
	alias typeof(this) Node;
	alias Node*[] ChildList;
	
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
	
	void insertBack( Node* child )
	{
		assert( type != OpType.literal );
		m_children ~= child;
	}
	
	void insertBack( ElemType value )
	{
		assert( type == OpType.literal );
		m_values ~= value;
	}
	
	/* Used for non-literal construction. */
	this(OpType type)
	{
		assert(type != OpType.literal);
		this.type = type;
		this.children = new Node*[0]; //make!(SList, Node)();
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
	
	pure Node* deepCopy() const
	{
		Node* result = (new Node[1]).ptr; // Hack.  There has to be a better way to allocate one of these with 0-args?
		result.type = this.type;
		if ( type == OpType.literal )
			result.m_values = this.m_values.dup;
		else
		{
			result.m_children = new Node*[this.m_children.length];
			foreach( i, child; this.m_children )
				result.m_children[i] = this.m_children[i].deepCopy();
		}
		return result;
	}
}

final class ParserBuilder(ElemType)
{
	/+
	private alias Transition!ElemType        Transition;
	private alias AutomatonFragment!ElemType Fragment;
	private alias AutomatonState!ElemType    State;
	+/
	private alias GrammarNode!ElemType       Node;
	
	//private SList!OpType operatorStack;
	//private SList!SList!Node operandStack;
	private SList!(Node*) parents;
	private Node* parent = null;
	private Node* root = null;
	
	this()
	{
		initialize();
	}
	
	void initialize()
	{
		//operatorStack = make!(SList, OpType)();
		//operandStack  = make!(SList, SList!Node)();
		parents = make!(SList!(Node*))(cast(Node*[])[]);
		root = new Node(OpType.sequence);
		parent = root;
	}
	
	private void pushOp(OpType op)
	{
		assert(op != OpType.literal);
		parents.insertFront(parent);
		parent = new Node(op);
		//operatorStack.insertFront(op);
		//operandStack.insertFront(make!(SList, Fragment));
	}
	
	/** Sequencing: Equivalent to the regex operation (ab). */
	void pushSequence()         { pushOp(OpType.sequence); }
	
	/** Alternation: Equivalent to the PEG operation (a/b). */
	void pushOrderedChoice()    { pushOp(OpType.orderedChoice); }
	
	/** Alternation: Equivalent to the regex operation (a|b). */
	void pushUnorderedChoice()  { pushOp(OpType.unorderedChoice); }
	
	/** Alternation */
	void pushShortestChoice()   { pushOp(OpType.shortestChoice); }
	
	/** Alternation */
	void pushLongestChoice()    { pushOp(OpType.longestChoice); }
	
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
		auto temp = parent;
		parent = parents.removeAny();
		parent.insertBack(temp);
	}
	
	void literal( ElemType elem )
	{
		parent.insertBack(new Node(elem));
	}
	
	void parser( const ParserBuilder pb )
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
		
		Node* a1 = pba.root; // Implicit sequence
		Node* a2 = a1.children[0]; // pushOpSequence
		Node* a3 = a2.children[0]; // pushOpUnorderedChoice
		Node* a4 = a3.children[0]; // x
		Node* a5 = a3.children[1]; // y
		
		auto pbb = new ParserBuilder!char();
		pbb.parser(pba);
		
		// pbb.root is it's own implicit opSequence.
		Node* b1 = pbb.root.children[0]; // pba's former implicit opSequence (copy of).
		Node* b2 = b1.children[0]; // copy of pba.pushOpSequence
		Node* b3 = b2.children[0]; // copy of pba.pushOpUnorderedChoice
		Node* b4 = b3.children[0]; // copy of pba.literal('x')
		Node* b5 = b3.children[1]; // copy of pba.literal('y')
		
		assert( b1.type == OpType.sequence );
		assert( b2.type == OpType.sequence );
		assert( b3.type == OpType.unorderedChoice );
		assert( b4.type == OpType.literal );
		assert( b5.type == OpType.literal );
		
		assert( a1 != b1 );
		assert( a2 != b2 );
		assert( a3 != b3 );
		assert( a4 != b4 );
		assert( a5 != b5 );
	}
	
	private static Node* flattenLiterals( Node* n )
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
	
	unittest
	{/+
	writeln("???");
		auto builder = new ParserBuilder!char;
	writeln("???");
		builder.pushOpSeq();
			builder.literal('x');
			builder.pushOpMaybe();
				builder.literal('y');
			builder.pop();
		builder.pop();
	writeln(builder.toString());+/
	}

}

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