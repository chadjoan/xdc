module xdc.gen_pipelines.main;

import std.file;
import std.stdio;
import std.conv;

import xdc.common.targets;

import xdc.gen_pipelines.Pipelines;

void main()
{
	std.file.write("src/xdc/generated/pipelines.d",
		to!string(
			"module xdc.generated.pipelines;\n"~
			"import xdc.common.IPipeline;\n"~
			"import xdc.common.targets;\n"~
			"import xdc.common.AstNode;\n"~
			"\n"~
			targetTable.emitTargetToPipelineFunc()~
			"\n"~makeInvalidPipeline()~
			"\n"~makeCPipeline()~
			"\n"~makeInterpretPipeline()));
}
