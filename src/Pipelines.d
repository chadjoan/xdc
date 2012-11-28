module Pipelines;

import targets;
import SemanticRule;
import PipelineGenerator;
import IPipeline;

string makeCPipeline()
{
	auto pl = PipelineGenerator(CompTarget.c);
	pl.addRule(finalCRule);
	return p1.toD();
}

mixin(makeCPipeline());

/+

Pipeline_C : IPipeline
{

	override AstNode execute( AstNode projectRoot )
	{
		/* DFA for compilation goes here. */
	}
}

+/