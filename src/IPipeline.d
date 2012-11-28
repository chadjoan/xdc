module IPipeline;

import AstNode;

interface IPipeline
{
	AstNode execute( AstNode projectRoot );
}
