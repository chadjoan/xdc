module rules.cbackend;

import SemanticRule;

const finalCRule = 
{
	SemanticRule rule;
	
	rule.recognizes(`. $save`);
	rule.substitutes(`&save`);
	
	rule.consumes(["AnyDCode"]);
	rule.produces([""]);
	
	return rule;
}();