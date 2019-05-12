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
		import xdc.common.reindent;
		code = rawCode;
        //code = reindent(startingIndentLevel, rawCode);
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

		protected abstract string dCodeBody(size_t indentLevel, ref string suffix, ref string[] symbolsById) const
		{
			assert(0);
		}

		DCode toDCode(size_t indentLevel, ref string[] symbolsById) const
		{
			import std.array : appender;
			import std.conv : to;

			auto thisFuncId = symbolsById.length;

			string entryFuncName = "n"~to!string(thisFuncId);
			symbolsById ~= entryFuncName;

			string suffix = "";
			string fnBody = dCodeBody(indentLevel+1, suffix, symbolsById);

			DCode result = DCode(indentLevel,`
				static Match `~entryFuncName ~
					`( const `~CallersElemType.stringof~`[] inputRange, size_t cursor, size_t ubound )
				{
					writefln("`~entryFuncName~`(%s,%s,%s)",inputRange,cursor,ubound);
					`~fnBody~`
				}
				`~suffix);
			
			result.entryFuncName = entryFuncName;
			return result;
		}

		DCode toDCode(size_t indentLevel) const
		{
			string[] symbolsById = new string[0];
			return toDCode(indentLevel, symbolsById);
		}

		Node deepCopy(size_t depth = 0) const
		{
			import std.range.primitives;

			auto obj = typeid(this).create();
			Node result = cast(Node)obj;
			//Node result = cast(Node)Object.factory(this.classinfo.name);
			assert(result);

			if ( this.hasValues && !this.values.empty )
			{
				auto newValues = new CallersElemType[this.values.length];
				for( size_t i = 0; i < this.values.length; i++ )
					newValues[i] = this.values[i];
				result.values = newValues;
			}

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

		protected override string dCodeBody(size_t indentLevel, ref string suffix, ref string[] symbolsById) const
		{
			assert( values.length == 1, "Flattened literals are currently unsupported." );
			return `
				/* Literal */
				if ( cursor >= ubound )
					return Match.failure(inputRange);
				else if ( inputRange[cursor] == '`~values[0]~`' )`~
				/* TODO!  How is equality/matching going to work for non-strings? */ `
					return Match.success(inputRange, cursor, cursor+1);
				else
					return Match.failure(inputRange);
			`;
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

		protected override string dCodeBody(size_t indentLevel, ref string suffix, ref string[] symbolsById) const
		{
			import std.array : appender;
			import std.conv : to;
			assert(children.length >= 1);
			
			auto result = appender!string;
			result.put("\n/* Sequence */");
			string prevCursor = "cursor";

			foreach ( i, child; children )
			{
				DCode childCode = child.toDCode(indentLevel, symbolsById);
				suffix ~= childCode.code;

				string thisMatchName = "m"~to!string(i);
				result.put(`
					auto `~thisMatchName~` = `~childCode.entryFuncName~
						`(inputRange, `~prevCursor~`, ubound);
					if ( !`~thisMatchName~`.successful )
						return Match.failure(inputRange);
				`);

				prevCursor = "m"~to!string(i)~".end";
			}

			result.put(
				`	return Match.success(inputRange, m0.begin, `~prevCursor~`);
			`);

			return result.data;
		}
	}

	final class EpsilonNode : GrammarNode
	{
		this() { super(OpType.epsilon); }

		protected override string dCodeBody(size_t indentLevel, ref string suffix, ref string[] symbolsById) const
		{
			return `
				/* Epsilon */
				return Match.success(inputRange, cursor, cursor);
			`;
		}
	}

	class OrderedChoice : GrammarParent
	{
		this() { super(OpType.orderedChoice); }
		this(OpType type) { super(type); }

		final protected override string dCodeBody(size_t indentLevel, ref string suffix, ref string[] symbolsById) const
		{
			import std.array : appender;
			import std.conv : to;
			assert(children.length >= 1);

			auto result = appender!string;
			result.put("\n/* Ordered Choice */");

			foreach ( i, child; children )
			{
				DCode childCode = child.toDCode(indentLevel, symbolsById);
				suffix ~= childCode.code;

				string thisMatchName = "m"~to!string(i);
				result.put(`
					auto `~thisMatchName~` = `~childCode.entryFuncName~
							`(inputRange, cursor, ubound);
					if ( `~thisMatchName~`.successful )
						return Match.success(
							inputRange, `
							~thisMatchName~`.begin, `
							~thisMatchName~`.end);
				`);
			}

			result.put(
				`	return Match.failure(inputRange);
			`);

			return result.data;
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

		protected override string dCodeBody(size_t indentLevel, ref string suffix, ref string[] symbolsById) const
		{
			assert(children.length == 1);

			DCode childCode = children[0].toDCode(indentLevel, symbolsById);
			suffix ~= childCode.code;

			return `
				/* Negative Lookahead */
				auto m = `~childCode.entryFuncName~
						`(inputRange, newCursor, ubound);
				if ( !m.successful )
					return Match.success(inputRange, cursor, cursor);
				else
					return Match.failure(inputRange);
				`;
		}
	}

	final class PosLookAhead : GrammarParent
	{
		this() { super(OpType.posLookAhead); }

		protected override string dCodeBody(size_t indentLevel, ref string suffix, ref string[] symbolsById) const
		{
			assert(children.length == 1);

			DCode childCode = children[0].toDCode(indentLevel, symbolsById);
			suffix ~= childCode.code;

			return `
				/* Positive Lookahead */
				auto m = `~childCode.entryFuncName~
						`(inputRange, newCursor, ubound);
				if ( m.successful )
					return Match.success(inputRange, cursor, cursor);
				else
					return Match.failure(inputRange);
			`;
		}
	}

	final class FullRepeat : GrammarParent
	{
		this() { super(OpType.fullRepeat); }

		protected override string dCodeBody(size_t indentLevel, ref string suffix, ref string[] symbolsById) const
		{
			assert(children.length == 1);

			DCode childCode = children[0].toDCode(indentLevel, symbolsById);
			suffix ~= childCode.code;

			return `
				/* Repetition */
				size_t newCursor = cursor;
				while ( true )
				{
					auto m = `~childCode.entryFuncName~
								`(inputRange, newCursor, ubound);
					if ( !m.successful )
						break;

					newCursor = m.end;
				}

				return Match.success(inputRange, cursor, newCursor);
			`;
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
