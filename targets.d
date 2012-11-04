module targets;

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