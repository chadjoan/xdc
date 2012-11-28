module PipelineGenerator;

import targets;
import SemanticRule;

struct PipelineGenerator
{
	PmlNfa totalNfa;
	PmlDfa totalDfa;
	
	this( CompTarget t )
	{
		TODO
	}

	void addRule( SemanticRule rule )
	{
		if ( !totalDfa.initialized )
			totalDfa.initialize();
	
		auto deps = ruleDependencyGraph.getDeps(rule);
		foreach ( dep; deps )
			addRule(dep);
		
		totalNfa =
			Nfa.or(
				totalNfa, 
				Nfa.semanticAction(rule.nfa, rule.substituteAction)
			);
	}
	
	void ensureDfaComputed()
	{
		if ( totalDfa.initialized )
			return;
		
		totalDfa = Nfa.toDfa(totalNfa);
	}

	string toD()
	{
		ensureDfaComputed();
		TODO
		return "";
	}
}
