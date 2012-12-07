module PipelineGenerator;

debug { import std.stdio; }

import misc;
import targets;
import IPipeline;
import SemanticRule;

final class PipelineGenerator
{
	/+
	PmlNfa totalNfa;
	PmlDfa totalDfa;
	+/
	string pipelineName;
	
	this( CompTarget t )
	{
		pipelineName = getPipelineName(t.toString());
	}

	void addRule( const ref SemanticRule rule )
	{
		stubAlert();
		
		/+
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
		+/
	}
	
	void ensureDfaComputed()
	{
		/+
		if ( totalDfa.initialized )
			return;
		
		totalDfa = Nfa.toDfa(totalNfa);
		+/
		stubAlert();
	}

	string toD()
	{
		ensureDfaComputed();
		stubAlert();
		
		return ` 
			class `~pipelineName~` : IPipeline
			{
				override AstNode execute( AstNode projectRoot )
				{
					/* DFA for compilation goes here. */
					return projectRoot;
				}
			}`;
	}
}
