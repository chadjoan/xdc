module SemanticRule;

debug { import std.stdio; }

final class SemanticRule
{
	/+
	PmlDfa nfa;
	??? substituteAction;
	+/
	
	private bool[string] featuresConsumed;
	private bool[string] featuresProduced;

	void recognizes( string pmlCode )
	{
		/+
		auto pmlTree = pmlParser.Root(pmlCode);
		nfa = toPmlNfa(pmlTree);
		+/
		debug writefln("%s, %s: stub", __FILE__, __LINE__);
	}
	
	void substitutes( string pmlCode )
	{
		
		debug writefln("%s, %s: stub", __FILE__, __LINE__);
	}
	
	void consumes( string[] features )
	{
		featuresConsumed = featuresConsumed.init;
		foreach( feature; features )
			featuresConsumed[feature] = true;
		featuresConsumed = featuresConsumed.rehash;
	}
	
	void produces( string[] features )
	{
		featuresProduced = featuresProduced.init;
		foreach( feature; features )
			featuresProduced[feature] = true;
		featuresProduced = featuresProduced.rehash;
	}
	
	bool consumesFeature( string feature )
	{
		debug writefln("%s, %s: stub", __FILE__, __LINE__);
	}
	
	bool producesFeature( string feature )
	{
		debug writefln("%s, %s: stub", __FILE__, __LINE__);
	}
}

