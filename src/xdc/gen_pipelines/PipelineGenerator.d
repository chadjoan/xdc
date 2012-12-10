module xdc.gen_pipelines.PipelineGenerator;

debug { import std.stdio; }

import xdc.common.misc;
import xdc.common.targets;
import xdc.common.SemanticRule;

final class PipelineGenerator
{
	/+
	PmlNfa totalNfa;
	PmlDfa totalDfa;
	+/
	string pipelineName;
	
	this( CompTarget t )
	{
		pipelineName = getPipelineName(t);
	}

	void addRule( const SemanticRule rule )
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
				override AstNode* execute( AstNode* projectRoot )
				{
					/* DFA for compilation goes here. */
					return projectRoot;
				}
			}`;
	}
}
