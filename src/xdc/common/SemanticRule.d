module SemanticRule;

debug { import std.stdio; }
import misc;

struct SemanticRule
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
		stubAlert();
	}
	
	void substitutes( string pmlCode )
	{
		
		stubAlert();
	}
	
	void consumes( string[] features )
	{
		featuresConsumed = featuresConsumed.init;
		foreach( feature; features )
			featuresConsumed[feature] = true;
		//featuresConsumed = featuresConsumed.rehash;
	}
	
	void produces( string[] features )
	{
		featuresProduced = featuresProduced.init;
		foreach( feature; features )
			featuresProduced[feature] = true;
		//featuresProduced = featuresProduced.rehash;
	}
	
	bool consumesFeature( string feature )
	{
		stubAlert();
	}
	
	bool producesFeature( string feature )
	{
		stubAlert();
	}
}

