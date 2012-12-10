module xdc.common.IPipeline;

import xdc.common.AstNode;

interface IPipeline
{
	AstNode* execute( AstNode* projectRoot );
}
