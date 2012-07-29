module grammars.pmlgrammar;

enum string pmlGrammar = ` 
PatternExpressions <
    PatternExpression*

PatternExpression <
      BinaryExpression

BlockExpression <
      "{" PatternExpression "}"

BinaryExpression <
      AndExpression

AndExpression <
      HasExpression (PatternExpression)?
      UnaryExpression (";" (PatternExpression)?)?

HasExpression <
    AtomicMatch (Capture)? "has" BlockExpression

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
      "."
    / Type Capture
    / Type
    / RelativePath
    / RelativePath Capture

RelativePath <
    "." Path

Path <
    Identifier "." Path

Type <
    Identifier

Capture <
    "$" Identifier

Integer < [0-9]+

Identifier < [a-zA-Z_] [a-zA-Z0-9_]*
`;
