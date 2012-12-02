module PipelineGenerator;

debug { import std.stdio; }

import targets;
import IPipeLine;
import SemanticRule;

struct PipelineGenerator
{
	/+
	PmlNfa totalNfa;
	PmlDfa totalDfa;
	+/
	string pipelineName;
	
	this( CompTarget t )
	{
		pipelineName = getPipelineName(toString(t));
	}

	void addRule( SemanticRule rule )
	{
		debug writefln("%s, %s: stub", __FILE__, __LINE__);
		
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
		debug writefln("%s, %s: stub", __FILE__, __LINE__);
	}

	string toD()
	{
		ensureDfaComputed();
		debug writefln("%s, %s: stub", __FILE__, __LINE__);
		
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
