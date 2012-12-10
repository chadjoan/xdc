module xdc.rules.cbackend;

import xdc.common.SemanticRule;

const finalCRule = 
{
	SemanticRule rule = new SemanticRule();
	
	rule.recognizes(`. $save`);
	rule.substitutes(`&save`);
	
	rule.consumes(["AnyDCode"]);
	rule.produces([""]);
	
	return rule;
};