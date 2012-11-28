module IPipeline;

import AstNode;

interface IPipeline
{
	AstNode execute( AstNode projectRoot );
}


string getPipelineName( string targetName )
{
	return "Pipeline_"~targetName;
}
