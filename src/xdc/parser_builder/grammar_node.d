module xdc.parser_builder.grammar_node;

import std.conv;

import xdc.parser_builder.op_type;


auto min(T, U)( T a, U b )
{
	return a < b ? a : b;
}

struct DCode
{
	string code;
	string entryFuncName;
}

template GrammarNodes(ElemType)
{
	alias GrammarNode Node;
	alias Node[] ChildList;

	abstract class GrammarNode
	{
		const OpType type;

		pure @property bool hasChildren() const            { return false; }
		pure @property const(ChildList) children() const   { assert(0); }
		@property ChildList children( ChildList newb )     { assert(0); }

		pure @property bool hasValues() const              { return false; }
		pure @property const(ElemType[]) values() const    { assert(0); }
		@property ElemType[] values( ElemType[] newb )     { assert(0); }

		this( OpType type )
		{
			this.type = type;
		}

		void insertBack( Node child )
		{
			assert(0);
		}

		void insertBack( ElemType value )
		{
			assert(0);
		}

		final string toString( uint depth ) const
		{
			string result = std.array.replicate(" ", min(depth*2,256)) ~ opTypeToString(type);
			if ( this.hasValues )
				result ~= " " ~ std.conv.to!string(this.values);
			else if ( this.hasChildren )
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
			DCode result;

			auto thisFuncId = symbolsById.length;
			result.entryFuncName = "n"~std.conv.to!string(thisFuncId);
			symbolsById ~= result.entryFuncName;

			result.code = "";
			string suffix = "";

			const string funcParams =
				"( const "~ElemType.stringof~"[] inputRange, size_t cursor, size_t ubound )";

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

		Node deepCopy() const
		{
			Node result = cast(Node)Object.factory(this.classinfo.name);
			if ( hasValues )
				result.values = this.values.dup;
			else if ( hasChildren )
			{
				auto newChildren = new Node[this.children.length];
				foreach( i, child; this.children )
					newChildren[i] = this.children[i].deepCopy();
				result.children = newChildren;
			}
			return result;
		}
	}

	final class GrammarLeaf : GrammarNode
	{
		private ElemType[] m_values;   /* When type == OpType.literal */

		pure override @property bool hasValues() const
		{
			return true;
		}

		pure override @property const(ElemType[]) values() const
		{
			return m_values;
		}

		override @property ElemType[] values( ElemType[] newb )
		{
			return m_values = newb;
		}

		this()
		{
			super(OpType.literal);
			this.m_values = new ElemType[0];
		}

		this(size_t nElements)
		{
			super(OpType.literal);
			this.m_values = new ElemType[nElements];
		}

		this(ElemType elem )
		{
			super(OpType.literal);
			this.m_values = new ElemType[1];
			this.m_values[0] = elem;
		}

		invariant()
		{
			assert( this.m_values !is null );
		}

		override void insertBack( ElemType value )
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

		auto newNode = new GrammarLeaf(elemCount);
		size_t i = 0;

		ElemType[] newValues = new ElemType[0];
		foreach( child; n.children )
			foreach ( val; child.values )
				newValues[i++] = val;
		newNode.values = newValues;

		return newNode;
	}

}