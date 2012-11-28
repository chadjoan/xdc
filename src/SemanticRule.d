module SemanticRule;

struct SemanticRule
{
	PmlDfa nfa;
	??? substituteAction;

	void recognize( string pmlCode )
	{
		auto pmlTree = pmlParser.Root(pmlCode);
		nfa = toPmlNfa(pmlTree);
		TODO
	}
	
	void substitute( string pmlCode )
	{
		
		TODO
	}
	
	
}

