module xdc.parser_builder.parser_builder;

import xdc.common.slist;
import std.stdio;
/+
import std.array;
import std.conv;
import std.range;
+/

import xdc.parser_builder.op_type;
import xdc.parser_builder.grammar_node;

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

struct MatchT(CallersElemType)
{
	alias typeof(this) Match;

	bool successful;
	const(CallersElemType)[][] matches;

	const(CallersElemType)[] input;
	size_t begin, end;

	static Match success(const CallersElemType[] input, size_t begin, size_t end)
	{
		Match m;
		m.successful = true;
		m.matches = new const(CallersElemType)[][1];
		m.matches[0] = input[begin..end]; // TODO: have a way to be more complex.
		m.input = input;
		m.begin = begin;
		m.end = end;
		return m;
	}

	pure static Match failure(const CallersElemType[] input)
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

final class ParserBuilder(CallersElemType)
{
	mixin GrammarNodes!CallersElemType;

	import std.array : Appender, appender;
	import std.exception : enforce;

	final class Scope
	{
		GrammarParent      parent;
		Appender!(Node[])  children;

		this(GrammarParent parent)
		{
			this.parent   = parent;
			this.children = appender!(Node[])();
		}
	}

	/+
	private alias Transition!CallersElemType        Transition;
	private alias AutomatonFragment!CallersElemType Fragment;
	private alias AutomatonState!CallersElemType    State;
	+/
	//private alias GrammarNode!CallersElemType       Node;

	bool delayNecessaryLowerings = false;

	private bool inGrammarDefinition = false;

	//private SList!OpType operatorStack;
	//private SList!SList!Node operandStack;

	// The first node inserted into this SList is the root node.
	// The most recently inserted node will represent the currently enclosing
	// scope.
	private SList!(Scope)  scopeStack;

	// Most recently encountered ops/nodes are placed towards the front of the
	// scope list.
	//private SList!(Node)           nodesInCurrentScope;

	//private GrammarParent parent = null;
	private GrammarParent root = null;

	this()
	{
		initialize();
	}

	void initialize()
	{
		//nodesInCurrentScope = make!(SList!(Node))(cast(Node[])[]);
		scopeStack = SList!Scope();
		//nodesInCurrentScope = SList!Node();
	}

	/// Called at the start of the parser's grammar definition.
	/// In other words, this must be called before any grammar definition
	/// methods like pushSequence, pushOrderedChoice, literal, and so on.
	void beginGrammarDefinition()
	{
		assert(!inGrammarDefinition);
		assert(scopeStack.empty);
		// TODO: Maybe this should be OpType.define with a name of "opCall"
		root = new Sequence;
		scopeStack.insertFront(new Scope(root));
		invalidateSemanticAnalysis();
		inGrammarDefinition = true;
	}

	/// Called at the end of the parser's grammar definition.
	/// This leaves the parser builder in a state where it is prepared to
	/// generate code that will parse the previously given grammar definition.
	/// This must be called after calling beginGrammarDefinition, and would
	/// naturally follow grammar definition methods like pushOrderedChoice,
	/// literal, pop, and so on.
	/// This must be called before calling any methods that perform semantic
	/// analysis of the grammar or do any parser generation, such as
	/// semanticAnalysis or toDCode.
	void endGrammarDefinition()
	{
		assert(inGrammarDefinition);
		assert(!scopeStack.empty);
		inGrammarDefinition = false;

		// Can't call 'pop' because it will error that there was no
		// corresponding 'push' call: in this case, there wasn't, and that
		// is OK; there is only one root node.
		uncheckedPop();
		assert(scopeStack.empty);
	}

	/// Performs any lowerings or optimizations of the grammar before any
	/// machine generation or code generation is performed.
	/// This must be called after endGrammarDefinition.
	/// This method is idempotent and will only perform any actions once for
	/// the most recent call to endGrammarDefinition.
	/// In most situations, the caller/owner of the ParserBuilder object will
	/// not need to call this method. This method will automatically be called
	/// when the first code generating function is called, assuming it has
	/// not been called already by the caller/owner of the ParserBuilder object.
	/// The only reason this exists separate from the code generation methods
	/// as a part of the public API is to allow callers to control when
	/// semantic analysis calculations are performed.
	private bool semanticAnalysisAlreadyPerformed = false;
	void semanticAnalysis()
	{
		enforce(root !is null, "Must define a grammar before calling 'semanticAnalysis', see 'beginGrammarDefinition' and 'endGrammarDefinition'.");
		enforce(!inGrammarDefinition, "Cannot run semantic analysis from within grammar definition: "~
			"ParserBuilder method 'endGrammarDefinition' must be called before calling 'semanticAnalysis'.");
		assert(scopeStack.empty);
		if ( semanticAnalysisAlreadyPerformed )
			return;
		scope(success)
			semanticAnalysisAlreadyPerformed = true;
		// TODO
	}

	/// Indicates to the ParserBuilder that semantic analysis must be performed
	/// before the next code generation request. This is unlikely to ever be
	/// needed externally, but might be helpful for workarounds.
	void invalidateSemanticAnalysis()
	{
		semanticAnalysisAlreadyPerformed = false;
	}

	private void checkInsideGrammarDef(string funcName = __FUNCTION__)()
	{
		enforce(inGrammarDefinition, "'beginGrammarDefinition' must be called before using grammar defining methods like '"~funcName~"'.");
		assert(!scopeStack.empty);
	}

	private @property auto pushOp(OpType op)()
	{
		static assert(op != OpType.literal);

		checkInsideGrammarDef();
		//nodesInCurrentScope.insertFront(parent);

		auto newNode = mixin(`new `~toClassName(op));
		auto newScope = new Scope(newNode);

		auto enclosingScope = scopeStack.front;
		enclosingScope.children.put(newNode);

		scopeStack.insertFront(newScope);

		return newNode;
	}

	unittest
	{
		// Test for nesting to work well.
		auto pb0 = new ParserBuilder!char();
		pb0.beginGrammarDefinition();
		pb0.literal('0');
		pb0.endGrammarDefinition();

		assert(pb0.root !is null);
		assert(pb0.root.canHaveChildren);
		assert(pb0.root.children.length == 1);
		assert(pb0.root.children[0].hasValues);
		assert(pb0.root.children[0].values == "0");

		auto pb1 = new ParserBuilder!char();
		pb1.beginGrammarDefinition();
		pb1.literal('0');
		pb1.pushSequence();
			pb1.literal('A');
			pb1.literal('B');
		pb1.pop();
		pb1.literal('1');
		pb1.endGrammarDefinition();

		assert(pb1.root !is null);
		assert(pb1.root.canHaveChildren);
		assert(pb1.root.children.length == 3);
		assert(pb1.root.children[0].hasValues);
		assert(pb1.root.children[0].values == "0");
		assert(pb1.root.children[1].canHaveChildren);
		assert(pb1.root.children[1].children.length == 2);
		assert(pb1.root.children[1].children[0].hasValues);
		assert(pb1.root.children[1].children[0].values == "A");
		assert(pb1.root.children[1].children[1].hasValues);
		assert(pb1.root.children[1].children[1].values == "B");
		assert(pb1.root.children[2].hasValues);
		assert(pb1.root.children[2].values == "1");

		auto pb2 = new ParserBuilder!char();
		pb2.beginGrammarDefinition();
		pb2.literal('0');
		pb2.pushSequence();
			pb2.literal('A');
			pb2.pushSequence();
				pb2.literal('x');
				pb2.literal('y');
			pb2.pop();
			pb2.literal('B');
		pb2.pop();
		pb2.literal('1');
		pb2.endGrammarDefinition();

		assert(pb2.root !is null);
		assert(pb2.root.canHaveChildren);
		assert(pb2.root.children.length == 3);
		assert(pb2.root.children[0].hasValues);
		assert(pb2.root.children[0].values == "0");
		assert(pb2.root.children[1].canHaveChildren);
		assert(pb2.root.children[1].children.length == 3);
		assert(pb2.root.children[1].children[0].hasValues);
		assert(pb2.root.children[1].children[0].values == "A");
		assert(pb2.root.children[1].children[1].canHaveChildren);
		assert(pb2.root.children[1].children[1].children.length == 2);
		assert(pb2.root.children[1].children[1].children[0].hasValues);
		assert(pb2.root.children[1].children[1].children[0].values == "x");
		assert(pb2.root.children[1].children[1].children[1].hasValues);
		assert(pb2.root.children[1].children[1].children[1].values == "y");
		assert(pb2.root.children[1].children[2].hasValues);
		assert(pb2.root.children[1].children[2].values == "B");
		assert(pb2.root.children[2].hasValues);
		assert(pb2.root.children[2].values == "1");

		auto pb3 = new ParserBuilder!char();
		pb3.beginGrammarDefinition();
		pb3.literal('0');
		pb3.pushSequence();
			pb3.literal('A');
			pb3.pushSequence();
				pb3.literal('x');
				pb3.pushSequence();
					pb3.literal('X');
					pb3.literal('Y');
				pb3.pop();
				pb3.literal('y');
			pb3.pop();
			pb3.literal('B');
		pb3.pop();
		pb3.literal('1');
		pb3.endGrammarDefinition();

		assert(pb3.root !is null);
		assert(pb3.root.canHaveChildren);
		assert(pb3.root.children.length == 3);
		assert(pb3.root.children[0].hasValues);
		assert(pb3.root.children[0].values == "0");
		assert(pb3.root.children[1].canHaveChildren);
		assert(pb3.root.children[1].children.length == 3);
		assert(pb3.root.children[1].children[0].hasValues);
		assert(pb3.root.children[1].children[0].values == "A");
		assert(pb3.root.children[1].children[1].canHaveChildren);
		assert(pb3.root.children[1].children[1].children.length == 3);
		assert(pb3.root.children[1].children[1].children[0].hasValues);
		assert(pb3.root.children[1].children[1].children[0].values == "x");
		assert(pb3.root.children[1].children[1].children[1].canHaveChildren);
		assert(pb3.root.children[1].children[1].children[1].children.length == 2);
		assert(pb3.root.children[1].children[1].children[1].children[0].hasValues);
		assert(pb3.root.children[1].children[1].children[1].children[0].values == "X");
		assert(pb3.root.children[1].children[1].children[1].children[1].hasValues);
		assert(pb3.root.children[1].children[1].children[1].children[1].values == "Y");
		assert(pb3.root.children[1].children[1].children[2].hasValues);
		assert(pb3.root.children[1].children[1].children[2].values == "y");
		assert(pb3.root.children[1].children[2].hasValues);
		assert(pb3.root.children[1].children[2].values == "B");
		assert(pb3.root.children[2].hasValues);
		assert(pb3.root.children[2].values == "1");
	}

	/** Sequencing: Equivalent to the regex operation (ab). */
	Sequence         pushSequence()
	{
		checkInsideGrammarDef!"ParserBuilder.pushSequence";
		return pushOp!(OpType.sequence);
	}

	/** Alternation: Equivalent to the PEG operation (a/b). */
	OrderedChoice    pushOrderedChoice()
	{
		checkInsideGrammarDef!"ParserBuilder.pushOrderedChoice";
		return pushOp!(OpType.orderedChoice);
	}

	/** Alternation: Equivalent to the regex operation (a|b). */
	/*un*/ OrderedChoice  pushUnorderedChoice()  { /+return pushOp!(OpType.unorderedChoice);+/
		checkInsideGrammarDef!"ParserBuilder.pushUnorderedChoice";
		return pushOp!(OpType.orderedChoice);
		writefln("%s, %s: Stub!", __FILE__, __LINE__);
	}

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
	//void pushIntersection()   { pushOp!(OpType.intersection); }

	/**
	Equivalent to the regex operation (a?).

	Since this is a unary operation, if more than one operand is given, then the
	operands are placed in a sequence that will then be operated on.
	*/
	Maybe pushMaybe()
	{
		checkInsideGrammarDef!"ParserBuilder.pushMaybe";
		return pushOp!(OpType.maybe);
	}

	/**
	Negates its operand.

	Since this is a unary operation, if more than one operand is given, then the
	operands are placed in a sequence that will then be operated on.
	*/
	//void pushComplement()   { pushOp!(OpType.complement); }

	/**
	Equivalent to the regex operation (a*?).

	Since this is a unary operation, if more than one operand is given, then the
	operands are placed in a sequence that will then be operated on.
	*/
	//void pushLazyRepeat() { pushOp!(OpType.lazyRepeat); }

	/**
	Equivalent to the regex operation (a*).

	Since this is a unary operation, if more than one operand is given, then the
	operands are placed in a sequence that will then be operated on.
	*/
	//void pushGreedyRepeat() { pushOp!(OpType.greedyRepeat); }

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
	FullRepeat pushFullRepeat()
	{
		checkInsideGrammarDef!"ParserBuilder.pushFullRepeat";
		return pushOp!(OpType.fullRepeat);
	}

	/** Terminates a list of operands for an operator given by pushOpName(). */
	void pop()
	{
		//auto temp = parent;
		if ( scopeStack.empty )
			throw new Exception("Attempt to 'pop' with no corresponding 'push___'.");

		uncheckedPop();
	}

	private void uncheckedPop()
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

		auto completedScope = scopeStack.front();
		completedScope.parent.children = completedScope.children.data;
		
		scopeStack.removeFront();

		//parent = nodesInCurrentScope.removeFront();

		//if ( !delayNecessaryLowerings )
		//	temp = necessaryLowerings(temp);

		//parent.insertBack(temp);
	}

	void putNode( Node n )
	{
		enforce( !scopeStack.empty, "The 'begin' method (on a ParserBuilder object) must be called before 'putNode' is called." );
		scopeStack.front;
	}

	void literal( CallersElemType elem )
	{
		assert(!scopeStack.empty);
		auto currentScope = this.scopeStack.front();
		currentScope.children.put(new GrammarLeaf(elem));
	}

	void compose( const ParserBuilder pb )
	{
		checkInsideGrammarDef!"ParserBuilder.compose";
		if ( pb is this )
			throw new Exception("Adding a parser to itself is not supported."
				~"  This probably wouldn't do what's expected anyways.");
		assert(!scopeStack.empty);
		assert(pb.scopeStack.empty);
		auto currentScope = this.scopeStack.front();
		currentScope.children.put(pb.root.deepCopy());
	}

	unittest
	{
		auto pba = new ParserBuilder!char();
		pba.beginGrammarDefinition();
		pba.pushSequence();
			pba.pushUnorderedChoice();
				pba.literal('x');
				pba.literal('y');
			pba.pop();
		pba.pop();
		pba.endGrammarDefinition();

		Node a1 = pba.root; // Implicit sequence
		auto a2 = a1.children[0]; // pushOpSequence
		auto a3 = a2.children[0]; // pushOpUnorderedChoice
		auto a4 = a3.children[0]; // x
		auto a5 = a3.children[1]; // y

		auto pbb = new ParserBuilder!char();
		pbb.beginGrammarDefinition();
		pbb.compose(pba);
		pbb.endGrammarDefinition();

		// pbb.root is it's own implicit opSequence.
		auto b1 = pbb.root.children[0]; // pba's former implicit opSequence (copy of).
		auto b2 = b1.children[0]; // copy of pba.pushOpSequence
		auto b3 = b2.children[0]; // copy of pba.pushOpUnorderedChoice
		auto b4 = b3.children[0]; // copy of pba.literal('x')
		auto b5 = b3.children[1]; // copy of pba.literal('y')

		assert( b1.type == OpType.sequence );
		assert( b2.type == OpType.sequence );
		//assert( b3.type == OpType.unorderedChoice ); // TODO
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

	private static Node necessaryLowerings( Node n )
	{
		n = coalesceUnaryArgs(n); // Must go before unary ops get lowered into other things.
		return n;
	}

	unittest
	{
		alias GrammarNodes!(char) StrGrammar;
		auto n = new StrGrammar.Sequence;
		n.insertBack(new StrGrammar.GrammarLeaf('a'));
		n.insertBack(new StrGrammar.GrammarLeaf('b'));
		n.insertBack(new StrGrammar.GrammarLeaf('c'));
		auto n2 = StrGrammar.flattenLiterals(n);
		assert( n2.type == OpType.literal );
		assert( n2.values[0] == 'a' );
		assert( n2.values[1] == 'b' );
		assert( n2.values[2] == 'c' );
	}

	override string toString()
	{
		return root.toString();
	}
	
	string toDCode(string name)
	{
		return toDCode(0, name);
	}

	string toDCode(size_t indentLevel, string name)
	{
		import xdc.common.reindent;
		assert(name != null);

		enforce(root !is null, "Must define a grammar before calling 'toDCode', see 'beginGrammarDefinition' and 'endGrammarDefinition'.");
		enforce(scopeStack.empty, "ParserBuilder method 'endGrammarDefinition' must be called before calling 'toDCode'.");
	
		invalidateSemanticAnalysis();

		// TODO: eliminateNullaryExpressions(root);

		auto guts = root.toDCode(indentLevel+1);
		

		/+return DCode(indentLevel, `
			struct `~name~`
			{
				alias MatchT!(`~CallersElemType.stringof~`) Match;

				`~guts.code~`
			}
		`).code;+/

		return DCode(indentLevel, reindent(indentLevel, `
			struct `~name~`
			{
				alias MatchT!(`~CallersElemType.stringof~`) Match;

				`~guts.code~`
			}
		`)).code;
	}

}


string makeParser()
{
	auto builder = new ParserBuilder!char;
	builder.beginGrammarDefinition();
		builder.pushSequence();
			builder.literal('x');
			builder.pushMaybe();
				builder.literal('y');
			builder.pop();
		builder.pop();
	builder.endGrammarDefinition();
	return builder.toDCode("callMe");
}

/+
void main()
{
	import std.stdio;
		import xdc.common.reindent;
	auto foo = makeParser();
	writeln("Before reindentation:");
	writeln(foo);
	writeln("");
	writeln("After reindentation:");
	writeln(reindent(0, foo));
}
+/

const foo = makeParser();

pragma(msg, foo);

mixin(foo);


void main()
{
	auto builder = new ParserBuilder!char;
	builder.beginGrammarDefinition();
		builder.pushSequence();
			builder.literal('x');
			builder.pushMaybe();
				builder.literal('y');
			builder.pop();
		builder.pop();
	builder.endGrammarDefinition();
	writefln(builder.toString());
	writefln("");

	auto m = callMe.n0("x",0,1);
	writefln("%s",m.successful);
	m = callMe.n0("xy",0,2);
	writefln("%s",m.successful);
	m = callMe.n0("xyz",0,3);
	writefln("%s",m.successful);
	m = callMe.n0("q",0,1);
	writefln("%s",m.successful);
	m = callMe.n0("",0,0);
	writefln("%s",m.successful);
	//writefln("Now then, let's do this.\n");
	//writeln(foo);
}
