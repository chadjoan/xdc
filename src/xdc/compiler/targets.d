module targets;

import IPipeline : getPipelineName;

private TargetTable defineTargets()
{
	TargetTable t;
	
	//      (  enum        , toString      , default   )
	//      (    name      ,   contents    , extension )
	t.define("invalid"     , "00000000"    , "000"     );
	t.define("c"           , "C"           , "c"       );
	t.define("interpret"   , "interpret"   , "err"     );
	
	return t;
}

private const targetTable = defineTargets();
mixin(targetTable.emitTargetEnum());
mixin(targetTable.emitTargetToStringFunc());
mixin(targetTable.emitStringToTargetFunc());
mixin(targetTable.emitTargetToExtFunc());
mixin(targetTable.emitTargetToPipelineFunc());

unittest
{
	assert( toString(CompTarget.c) == "C" );
	assert( toTarget("C") == CompTarget.c );
	assert( toExt(CompTarget.c) == "c" );
	// TODO: test the toPipeline() function
}




private struct TargetTable
{
	string[] enumNames;
	string[] toStringContents;
	string[] defaultExts;
	
	void initialize()
	{
		if ( enumNames !is null )
			return;
		
		enumNames = new string[0];
		toStringContents = new string[0];
		defaultExts = new string[0];
	}
	
	void define( string enumName, string toStringContent, string defaultExt )
	{
		initialize();
		
		enumNames ~= enumName;
		toStringContents ~= toStringContent;
		defaultExts ~= defaultExt;
	}
	
	string emitTargetEnum() const
	{
		string result = "";
		
		result ~= "enum CompTarget\n{\n";
		for ( int i = 0; i < enumNames.length; i++ )
			result ~= "\t" ~ enumNames[i] ~ ",\n";
		result ~= "}\n";
		
		return result;
	}
	
	
	string emitTargetToStringFunc() const
	{
		string result = "";
		
		result ~= "string toString( CompTarget t )\n{\n";
		result ~= "\tfinal switch( t )\n\t{\n";

		for ( int i = 0; i < enumNames.length; i++ )
			result ~= "\t\tcase CompTarget." ~ enumNames[i] ~ 
				": return \"" ~ toStringContents[i] ~ "\";\n";

		result ~= "\t}\n";
		result ~= "\tassert(0);\n";
		result ~= "}\n";
		
		return result;
	}
	
	string emitStringToTargetFunc() const
	{
		string result = "";
		
		result ~= "CompTarget toTarget( string text )\n{\n";
		result ~= "\tswitch( text )\n\t{\n";

		for ( int i = 0; i < enumNames.length; i++ )
			result ~= "\t\tcase \"" ~ toStringContents[i] ~ 
				"\": return CompTarget." ~ enumNames[i] ~";\n";

		result ~= "\t\tdefault: return CompTarget.invalid;\n";
		result ~= "\t}\n";
		result ~= "\tassert(0);\n";
		result ~= "}\n";
		
		return result;
	}
	
	string emitTargetToExtFunc() const
	{
		string result = "";
		
		result ~= "string toExt( CompTarget t )\n{\n";
		result ~= "\tfinal switch( t )\n\t{\n";
		
		for ( int i = 0; i < enumNames.length; i++ )
			result ~= "\t\tcase CompTarget." ~ enumNames[i] ~ 
				": return \"" ~ defaultExts[i] ~ "\";\n";
		
		result ~= "\t}\n";
		result ~= "\tassert(0);\n";
		result ~= "}\n";
		
		return result;
	}
	
	string emitTargetToPipelineFunc() const
	{
		string result = "";
		
		result ~= "string toPipeline( CompTarget t )\n{\n";
		result ~= "\tfinal switch( t )\n\t{\n";
		
		for ( int i = 0; i < enumNames.length; i++ )
			result ~= "\t\tcase CompTarget." ~ enumNames[i] ~ 
				": return new " ~ getPipelineName(enumNames[i]) ~ "();\n";
		
		result ~= "\t}\n";
		result ~= "\tassert(0);\n";
		result ~= "}\n";
		
		return result;
	}
}

/+

private template defineTarget( alias definitionType )
{
	const string defineTarget = 
		// -------------------------------------------------------------------//
		//                                                                    //
		//             (  enum name   , string version, ext )                 //
		//                                                                    //
		definitionType!("invalid"     , "00000000"    , "000" ) ~
		definitionType!("c"           , "C"           , "c"   ) ~
		definitionType!("interpret"   , "interpret"   , "err" ) ~
		//definitionType!("java"        , "Java"        , ".jar" ) ~
		//definitionType!("javaScript"  , "JavaScript"  , ".js"  ) ~
		"";
}

private template targetEnumDefinition( string name, string text, string ext )
{
	const string targetEnumDefinition = "\t" ~name~ ",\n";
}

private const targetEnum =
	"enum CompTarget\n{\n"~
	defineTarget!(targetEnumDefinition)~
	"}\n";

pragma(msg, targetEnum);
mixin(targetEnum);

private template targetToStrDefinition( string name, string text, string ext )
{
	const string targetToStrDefinition = "\t\tcase CompTarget." ~ name ~ ": return \"" ~ text ~ "\";\n";
}

private const targetToStrCode =
	"string toString( CompTarget t )\n{\n"~
	"\tfinal switch( t )\n\t{\n"~
	defineTarget!(targetToStrDefinition)~
	"\t}\n"~
	"\tassert(0);\n"~
	"}\n";

pragma(msg, targetToStrCode);
mixin(targetToStrCode);

private template strToTargetDefinition( string name, string text, string ext )
{
	const string strToTargetDefinition = "\t\tcase \"" ~ text ~ "\": return CompTarget." ~ name ~";\n";
}

private const strToTargetCode =
	"CompTarget toTarget( string text )\n{\n"~
	"\tswitch( text )\n\t{\n"~
	defineTarget!(strToTargetDefinition)~
	"\t\tdefault: return CompTarget.invalid;\n"~
	"\t}\n"~
	"\tassert(0);\n"~
	"}\n";

pragma(msg, strToTargetCode);
mixin(strToTargetCode);

private template targetToExtDefinition( string name, string text, string ext )
{
	const string targetToExtDefinition = "\t\tcase CompTarget." ~ name ~ ": return \"" ~ ext ~ "\";\n";
}

private const targetToExtCode =
	"string toExt( CompTarget t )\n{\n"~
	"\tfinal switch( t )\n\t{\n"~
	defineTarget!(targetToExtDefinition)~
	"\t}\n"~
	"\tassert(0);\n"~
	"}\n";

pragma(msg, targetToExtCode);
mixin(targetToExtCode);
+/