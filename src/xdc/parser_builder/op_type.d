module xdc.parser_builder.op_type;

private struct OpTypeTable
{
	string[] enumNames;
	string[] toStringContents;
	string[] classNames;

	void initialize()
	{
		if ( enumNames !is null )
			return;

		enumNames = new string[0];
		toStringContents = new string[0];
	}

	void define( string enumName, string className )
	{
		initialize();

		enumNames ~= enumName;
		toStringContents ~= enumName;
		classNames ~= className;
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

	string emitToClassNameFunc() const
	{
		string result = "";

		result ~= "string toClassName( OpType t )\n{\n";
		result ~= "\tfinal switch( t )\n\t{\n";

		for ( int i = 0; i < classNames.length; i++ )
			result ~= "\t\tcase OpType." ~ enumNames[i] ~
				": return \"" ~ classNames[i] ~ "\";\n";

		result ~= "\t}\n";
		result ~= "\tassert(0,\"Attempt to toClassName an invalid OpType.\");\n";
		result ~= "}\n";

		return result;
	}
}

private OpTypeTable defineOpTypes()
{
	OpTypeTable t;

	t.define("epsilon"          , "EpsilonNode"     );
	t.define("literal"          , "GrammarLeaf"     );
	t.define("sequence"         , "Sequence"        );
	t.define("orderedChoice"    , "OrderedChoice"   );
	t.define("unorderedChoice"  , "UnorderedChoice" );
	t.define("intersection"     , "Intersection"    );
	t.define("maybe"            , "Maybe"           );
	t.define("complement"       , "Complement"      );
	t.define("negLookAhead"     , "NegLookAhead"    );
	t.define("posLookAhead"     , "PosLookAhead"    );
	t.define("lazyRepeat"       , "LazyRepeat"      );
	t.define("greedyRepeat"     , "GreedyRepeat"    );
	t.define("fullRepeat"       , "FullRepeat"      );
	t.define("defineRule"       , "DefineRule"      );
	t.define("matchRule"        , "MatchRule"       );
	//t.define("dfaNode"); ?? has all "dfaTransition" children.
	//t.define("dfaTransition"); child[0] == the GrammarNode that must match. child[1] == the next state to move into.

	return t;
}

const opTypeTable = defineOpTypes();
mixin(opTypeTable.emitEnum());
mixin(opTypeTable.emitToStringFunc());
mixin(opTypeTable.emitToClassNameFunc());