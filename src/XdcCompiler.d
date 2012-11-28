module XdcCompiler;

import std.stdio;
import std.file : write, read;

import generated.dparser;

import targets;

alias ParseTree* AstNode;

class XdcCompiler
{
	string outputFile = null;
	CompTarget target = CompTarget.c;
	
	private string[] sourceFiles = new string[0];
	private AstNode projectRoot = new AstNode();
	
	this()
	{
		sourceFiles = new string[0];
	}

	void addSourceFile( string filePath )
	{
		writefln("Added source: '%s'", filePath);
		sourceFiles ~= filePath;
	}
	
	void run()
	{
		if ( outputFile is null )
			outputFile = "out." ~ toExt(target);
		
		/*
		The compile creates a single abstract syntax tree from multiple modules.
		
		The method by which this is accomplished is very simple: the compiler's 
		syntax tree is just a projectRoot node that has, as its children, every
		module that the compiler parses.  The addTreeAsModule function is called
		repeatedly to construct this root node.
		
		The pipeline is later responsible for any module merging that may be 
		desired.
		*/
		foreach( source; sourceFiles )
		{
			// TODO: error handling.
			auto moduleRoot = D.Module(std.file.read(source));
			addTreeAsModule(projectRoot, moduleRoot);
		}
		
		auto p = targetToPipeline(target);
		auto outputNode = p.execute(projectRoot);

		enforce(D.getId!(outputNode.name) == D.getId!"XdcFinalOutput");
		
		std.file.write(outputNode.toCode(), outputFile);
	}
	
}

private void addTreeAsModule( AstNode projectRoot, AstNode moduleRoot )
{
	TODO
}