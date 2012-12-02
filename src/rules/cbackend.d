
const finalCRule =
{
	auto rule = new SemanticRule();
	
	rule.recognizes(`. $save`);
	rule.substitutes(`&save`);
	
	rule.consumes(["AnyDCode"]);
	rule.produces([""]);
	
	return rule;
};