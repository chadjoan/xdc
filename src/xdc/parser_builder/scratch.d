
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

	// The working conjecture is that (uv/xy)c == (uv|(^(uv)&xy))c
	//   (or, by De Morgan's law: (uv/xy)c == (uv|(^(uv|^(xy))))c )
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