module Pipelines;

import targets;
import SemanticRule;
import PipelineGenerator;
import IPipeline;

import rules.cbackend;

string makeCPipeline()
{
	auto pg = new PipelineGenerator(CompTarget.c);
	pg.addRule(finalCRule);
	return pg.toD();
}

/+
template splort()
{
	const string splort = makeCPipeline();
}

const str = splort!();
+/
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