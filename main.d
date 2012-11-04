module main;

import std.stdio;
import std.getopt;
import std.string;
import std.path : extension;

import targets;
import XdcCompiler;

private void printUsage()
{
	writefln("xdc Compiler");
	writefln("Usage:");
	writefln("  xdc files.d ... [options]");
	writefln("");
	writefln("Options:");
	//------  --------- 80 character limit -------------------------------------------------->
	writefln("  -h, --help                Show this usage info.");
	writefln("  -o, --output=file         Set the output file name.");
	writefln("                            This defaults to out.ext, where .ext is determined");
	writefln("                              by the chosen target.");
	writefln("  -t, --target=option       Determines what kind of output xdc produces.");
	writefln("                            Possible options are:");
	writefln("                            C          : Emit a .c file containing ANSI C89.");
	writefln("                            interpret  : Run the D code instead of compiling.");
	//writefln("                          Java       : Emit a Java .jar file (bytecode).");
	//writefln("                          JavaScript : Emit a .js file containing JavaScript.");
	//writefln("                          x86        : Emit an 32-bit x86 executable.");
	writefln("                            The default option is C.");
	//------  --------- 80 character limit -------------------------------------------------->
	
}

private int err(T...)(string fmtstr, T fmts)
{
	writefln(fmtstr, fmts);
	printUsage();
	return 1;
}

private bool argMatch( string arg, string[] matches )
{
	foreach ( possibility; matches )
		if ( icmp(arg, possibility) == 0 )
			return true;
	return false;
}

int main( string[] args )
{
	XdcCompiler compiler = new XdcCompiler();
	
	void setOutput( string opt, string file )
	{
		if ( compiler.outputFile == null )
			err("Output file specified twice.");
		else
			compiler.outputFile = file;
	}
	
	void setTarget( string opt, string target )
	{
		CompTarget t = toTarget(target);
		if ( t == CompTarget.invalid )
			err("Invalid compilation target: '%s'", target);
		else
			compiler.target = t;
		writefln("Setting target: %s", toString(t));
	}
	
	bool help = false;
	bool emitDebug = false;
	
	getopt(args,
		std.getopt.config.caseSensitive,
		std.getopt.config.bundling,
		std.getopt.config.passThrough,
		"help|h", &help,
		"output|o", &setOutput,
		"target|t", &setTarget,
		"debug|g", &emitDebug);
	
	if ( help )
	{
		printUsage();
		return 0;
	}
	
	// Remove the program name from the arg list.
	args = args[1..$];
	
	// Scan for .d files.
	foreach( arg; args )
	{
		if ( icmp(extension(arg),".d") == 0 )
			compiler.addSourceFile(arg);
		else
			return err("Unknown option '%s'", arg);
	}
	
	// Action!
	compiler.run();
	
	return 0;
}
