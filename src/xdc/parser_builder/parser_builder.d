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
	/+
	private alias Transition!CallersElemType        Transition;
	private alias AutomatonFragment!CallersElemType Fragment;
	private alias AutomatonState!CallersElemType    State;
	+/
	//private alias GrammarNode!CallersElemType       Node;

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
		//parents = make!(SList!(Node))(cast(Node[])[]);
		parents = SList!Node();

		// TODO: Maybe this should be OpType.define with a name of "opCall"
		root = new Sequence;
		parent = root;
	}

	private @property void pushOp(OpType op)()
	{
		static assert(op != OpType.literal);
		parents.insertFront(parent);
		parent = mixin(`new `~toClassName(op));
	}

	/** Sequencing: Equivalent to the regex operation (ab). */
	void pushSequence()         { pushOp!(OpType.sequence); }

	/** Alternation: Equivalent to the PEG operation (a/b). */
	void pushOrderedChoice()    { pushOp!(OpType.orderedChoice); }

	/** Alternation: Equivalent to the regex operation (a|b). */
	void pushUnorderedChoice()  { /+pushOp!(OpType.unorderedChoice);+/
		pushOp!(OpType.orderedChoice);
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
	void pushMaybe() { pushOp!(OpType.maybe); }

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
	void pushFullRepeat() { pushOp!(OpType.fullRepeat); }

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

	void literal( CallersElemType elem )
	{
		parent.insertBack(new GrammarLeaf(elem));
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
		auto a2 = a1.children[0]; // pushOpSequence
		auto a3 = a2.children[0]; // pushOpUnorderedChoice
		auto a4 = a3.children[0]; // x
		auto a5 = a3.children[1]; // y

		auto pbb = new ParserBuilder!char();
		pbb.compose(pba);

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
		assert(name != null);

		// TODO: eliminateNullaryExpressions(root);

		auto guts = root.toDCode();

		string result =
			"struct "~name~"\n"~
			"{\n"~
			"\talias MatchT!"~CallersElemType.stringof~" Match;\n"~
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
	return builder.toDCode("callMe");
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

