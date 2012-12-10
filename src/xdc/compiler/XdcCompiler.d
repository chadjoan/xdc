module xdc.compiler.XdcCompiler;

debug { import std.stdio; }
import std.stdio;
import std.conv;
import std.file : write, read;

import xdc.generated.parsers;
import xdc.generated.pipelines;

import xdc.common.AstNode;
import xdc.common.targets;
import xdc.common.IPipeline;

/* TODO: stub */
string toCode( AstNode* node )
{
	writefln("%s, %s: stub", __FILE__, __LINE__);
	return node.input[node.begin .. node.end];
}

class XdcCompiler
{
	string outputFile = null;
	CompTarget target = CompTarget.c;
	
	private string[] sourceFiles;
	private AstNode* projectRoot;
	
	this()
	{
		sourceFiles = new string[0];
		projectRoot = new AstNode();
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
			auto moduleRoot = D.Module(to!string(std.file.read(source)));
			addTreeAsModule(projectRoot, &moduleRoot);
		}
		
		auto p = toPipeline(target);
		auto outputNode = p.execute(projectRoot);

		debug writefln("%s, %s: TODO", __FILE__, __LINE__);
		//enforce(D.getId!(outputNode.name) == D.getId!"XdcFinalOutput");
		
		std.file.write(outputNode.toCode(), outputFile);
	}
	
}

private void addTreeAsModule( AstNode* projectRoot, AstNode* moduleRoot )
{
	debug writefln("%s, %s: stub", __FILE__, __LINE__);
}