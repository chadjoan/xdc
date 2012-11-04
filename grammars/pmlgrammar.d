module grammars.pmlgrammar;

enum string pmlGrammar = "PML: Foo <- blank";
/+
enum string pmlGrammar = ` 
PML:

PatternExpressions < PatternExpression+ !.

PatternExpression < BinaryExpression

BlockExpression < "{" PatternExpression "}"

BinaryExpression < SeqExpression

SeqExpression < SeqElement+

SeqElement < ScopingExpression
	/ UnaryExpression ";"

ScopingExpression <
	  HasExpression
	/ UnaryOp BlockExpression

HasExpression <
      AtomicMatch "has" UnaryExpression

UnaryExpression <
      UnaryOp UnaryExpression
    / BlockExpression
    / AtomicMatch

UnaryOp <
      "any"
    / "at_least"
    / "at_most"
    / "maybe"
    / "one_of"
    / "between" "(" Integer "," Integer ")"

AtomicMatch <
      Type Capture?
    / RelativePath Capture?
    / "." Capture?

RelativePath <
    "." Path

Path <
      Identifier "." Path
    / Identifier

Type <
    Identifier

Capture <
    "$" Identifier

Integer < [0-9]+

Identifier <- !UnaryOp [a-zA-Z_] [a-zA-Z0-9_]*
`;
+/