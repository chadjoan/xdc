module xdc.gen_pipelines.Pipelines;

import xdc.common.targets;
import xdc.common.SemanticRule;
import xdc.common.IPipeline;
import xdc.gen_pipelines.PipelineGenerator;

import xdc.rules.cbackend;

string makeInvalidPipeline()
{
	auto pg = new PipelineGenerator(CompTarget.invalid);
	pg.addRule(finalCRule());
	return pg.toD();
}

string makeCPipeline()
{
	auto pg = new PipelineGenerator(CompTarget.c);
	//pg.addRule(finalCRule());
	return pg.toD();
}

string makeInterpretPipeline()
{
	auto pg = new PipelineGenerator(CompTarget.interpret);
	//pg.addRule(finalCRule());
	return pg.toD();
}

/+
template splort()
{
	const string splort = makeCPipeline();
}

const str = splort!();
+/
/+mixin(makeCPipeline());+/

/+

Pipeline_C : IPipeline
{

	override AstNode execute( AstNode projectRoot )
	{
		/* DFA for compilation goes here. */
	}
}

+/