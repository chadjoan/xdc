module XdcCompiler;

import std.stdio;

import targets;

class XdcCompiler
{
	string outputFile = null;
	CompTarget target = CompTarget.c;

	void addSourceFile( string filePath )
	{
		writefln("Added source: '%s'", filePath);
	}
	
	void run()
	{
		if ( outputFile is null )
			outputFile = "out." ~ toExt(target);
		
		writefln("Ideally this will do something.");
	}
}