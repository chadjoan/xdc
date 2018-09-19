module generated.dparser;
import pegged.grammar;

struct GenericC(TParseTree)
{
    struct C
    {
    enum name = "C";
    static bool isRule(string s)
    {
        switch(s)
        {
            case "C.TranslationUnit":
            case "C.ExternalDeclaration":
            case "C.FunctionDefinition":
            case "C.PrimaryExpression":
            case "C.PostfixExpression":
            case "C.ArgumentExpressionList":
            case "C.UnaryExpression":
            case "C.IncrementExpression":
            case "C.PlusPlus":
            case "C.DecrementExpression":
            case "C.UnaryOperator":
            case "C.CastExpression":
            case "C.MultiplicativeExpression":
            case "C.AdditiveExpression":
            case "C.ShiftExpression":
            case "C.RelationalExpression":
            case "C.EqualityExpression":
            case "C.ANDExpression":
            case "C.ExclusiveORExpression":
            case "C.InclusiveORExpression":
            case "C.LogicalANDExpression":
            case "C.LogicalORExpression":
            case "C.ConditionalExpression":
            case "C.AssignmentExpression":
            case "C.AssignmentOperator":
            case "C.Expression":
            case "C.ConstantExpression":
            case "C.Declaration":
            case "C.DeclarationSpecifiers":
            case "C.InitDeclaratorList":
            case "C.InitDeclarator":
            case "C.StorageClassSpecifier":
            case "C.TypeSpecifier":
            case "C.StructOrUnionSpecifier":
            case "C.StructDeclarationList":
            case "C.StructDeclaration":
            case "C.SpecifierQualifierList":
            case "C.StructDeclaratorList":
            case "C.StructDeclarator":
            case "C.EnumSpecifier":
            case "C.EnumeratorList":
            case "C.Enumerator":
            case "C.EnumerationConstant":
            case "C.TypeQualifier":
            case "C.Declarator":
            case "C.DirectDeclarator":
            case "C.Pointer":
            case "C.TypeQualifierList":
            case "C.ParameterTypeList":
            case "C.ParameterList":
            case "C.ParameterDeclaration":
            case "C.IdentifierList":
            case "C.TypeName":
            case "C.AbstractDeclarator":
            case "C.DirectAbstractDeclarator":
            case "C.TypedefName":
            case "C.Initializer":
            case "C.InitializerList":
            case "C.Statement":
            case "C.LabeledStatement":
            case "C.CompoundStatement":
            case "C.DeclarationList":
            case "C.StatementList":
            case "C.ExpressionStatement":
            case "C.IfStatement":
            case "C.SwitchStatement":
            case "C.IterationStatement":
            case "C.WhileStatement":
            case "C.DoStatement":
            case "C.ForStatement":
            case "C.GotoStatement":
            case "C.ContinueStatement":
            case "C.BreakStatement":
            case "C.ReturnStatement":
            case "C.Return":
            case "C.Identifier":
            case "C.Keyword":
            case "C.Spacing":
            case "C.Comment":
            case "C.StringLiteral":
            case "C.DQChar":
            case "C.EscapeSequence":
            case "C.CharLiteral":
            case "C.IntegerLiteral":
            case "C.Integer":
            case "C.IntegerSuffix":
            case "C.FloatLiteral":
            case "C.Sign":
                return true;
            default:
                return false;
        }
    }
    mixin decimateTree;
    static TParseTree TranslationUnit(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.and!(ExternalDeclaration, pegged.peg.zeroOrMore!(pegged.peg.and!(pegged.peg.discard!(Spacing), ExternalDeclaration))), name ~ ".TranslationUnit")(p);
    }

    static TParseTree TranslationUnit(string s)
    {
        return pegged.peg.named!(pegged.peg.and!(ExternalDeclaration, pegged.peg.zeroOrMore!(pegged.peg.and!(pegged.peg.discard!(Spacing), ExternalDeclaration))), name ~ ".TranslationUnit")(TParseTree("", false,[], s));
    }

    static TParseTree ExternalDeclaration(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.or!(FunctionDefinition, Declaration), name ~ ".ExternalDeclaration")(p);
    }

    static TParseTree ExternalDeclaration(string s)
    {
        return pegged.peg.named!(pegged.peg.or!(FunctionDefinition, Declaration), name ~ ".ExternalDeclaration")(TParseTree("", false,[], s));
    }

    static TParseTree FunctionDefinition(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, pegged.peg.option!(DeclarationSpecifiers), Declarator, pegged.peg.option!(DeclarationList), CompoundStatement), name ~ ".FunctionDefinition")(p);
    }

    static TParseTree FunctionDefinition(string s)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, pegged.peg.option!(DeclarationSpecifiers), Declarator, pegged.peg.option!(DeclarationList), CompoundStatement), name ~ ".FunctionDefinition")(TParseTree("", false,[], s));
    }

    static TParseTree PrimaryExpression(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.or!(Identifier, CharLiteral, StringLiteral, FloatLiteral, IntegerLiteral, pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("("), Expression, pegged.peg.literal!(")"))), name ~ ".PrimaryExpression")(p);
    }

    static TParseTree PrimaryExpression(string s)
    {
        return pegged.peg.named!(pegged.peg.or!(Identifier, CharLiteral, StringLiteral, FloatLiteral, IntegerLiteral, pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("("), Expression, pegged.peg.literal!(")"))), name ~ ".PrimaryExpression")(TParseTree("", false,[], s));
    }

    static TParseTree PostfixExpression(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, PrimaryExpression, pegged.peg.zeroOrMore!(pegged.peg.or!(pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("["), Expression, pegged.peg.literal!("]")), pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("("), pegged.peg.literal!(")")), pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("("), ArgumentExpressionList, pegged.peg.literal!(")")), pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("."), Identifier), pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("->"), Identifier), pegged.peg.literal!("++"), pegged.peg.literal!("--")))), name ~ ".PostfixExpression")(p);
    }

    static TParseTree PostfixExpression(string s)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, PrimaryExpression, pegged.peg.zeroOrMore!(pegged.peg.or!(pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("["), Expression, pegged.peg.literal!("]")), pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("("), pegged.peg.literal!(")")), pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("("), ArgumentExpressionList, pegged.peg.literal!(")")), pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("."), Identifier), pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("->"), Identifier), pegged.peg.literal!("++"), pegged.peg.literal!("--")))), name ~ ".PostfixExpression")(TParseTree("", false,[], s));
    }

    static TParseTree ArgumentExpressionList(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, AssignmentExpression, pegged.peg.zeroOrMore!(pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!(","), AssignmentExpression))), name ~ ".ArgumentExpressionList")(p);
    }

    static TParseTree ArgumentExpressionList(string s)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, AssignmentExpression, pegged.peg.zeroOrMore!(pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!(","), AssignmentExpression))), name ~ ".ArgumentExpressionList")(TParseTree("", false,[], s));
    }

    static TParseTree UnaryExpression(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.or!(PostfixExpression, IncrementExpression, DecrementExpression, pegged.peg.spaceAnd!(Spacing, UnaryOperator, CastExpression), pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("sizeof"), UnaryExpression), pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("sizeof"), pegged.peg.literal!("("), TypeName, pegged.peg.literal!(")"))), name ~ ".UnaryExpression")(p);
    }

    static TParseTree UnaryExpression(string s)
    {
        return pegged.peg.named!(pegged.peg.or!(PostfixExpression, IncrementExpression, DecrementExpression, pegged.peg.spaceAnd!(Spacing, UnaryOperator, CastExpression), pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("sizeof"), UnaryExpression), pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("sizeof"), pegged.peg.literal!("("), TypeName, pegged.peg.literal!(")"))), name ~ ".UnaryExpression")(TParseTree("", false,[], s));
    }

    static TParseTree IncrementExpression(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, PlusPlus, UnaryExpression), name ~ ".IncrementExpression")(p);
    }

    static TParseTree IncrementExpression(string s)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, PlusPlus, UnaryExpression), name ~ ".IncrementExpression")(TParseTree("", false,[], s));
    }

    static TParseTree PlusPlus(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.literal!("++"), name ~ ".PlusPlus")(p);
    }

    static TParseTree PlusPlus(string s)
    {
        return pegged.peg.named!(pegged.peg.literal!("++"), name ~ ".PlusPlus")(TParseTree("", false,[], s));
    }

    static TParseTree DecrementExpression(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("--"), UnaryExpression), name ~ ".DecrementExpression")(p);
    }

    static TParseTree DecrementExpression(string s)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("--"), UnaryExpression), name ~ ".DecrementExpression")(TParseTree("", false,[], s));
    }

    static TParseTree UnaryOperator(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.or!(pegged.peg.literal!("-"), pegged.peg.literal!("&"), pegged.peg.literal!("*"), pegged.peg.literal!("+"), pegged.peg.literal!("~"), pegged.peg.literal!("!")), name ~ ".UnaryOperator")(p);
    }

    static TParseTree UnaryOperator(string s)
    {
        return pegged.peg.named!(pegged.peg.or!(pegged.peg.literal!("-"), pegged.peg.literal!("&"), pegged.peg.literal!("*"), pegged.peg.literal!("+"), pegged.peg.literal!("~"), pegged.peg.literal!("!")), name ~ ".UnaryOperator")(TParseTree("", false,[], s));
    }

    static TParseTree CastExpression(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.or!(UnaryExpression, pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("("), TypeName, pegged.peg.literal!(")"), CastExpression)), name ~ ".CastExpression")(p);
    }

    static TParseTree CastExpression(string s)
    {
        return pegged.peg.named!(pegged.peg.or!(UnaryExpression, pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("("), TypeName, pegged.peg.literal!(")"), CastExpression)), name ~ ".CastExpression")(TParseTree("", false,[], s));
    }

    static TParseTree MultiplicativeExpression(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, CastExpression, pegged.peg.zeroOrMore!(pegged.peg.spaceAnd!(Spacing, pegged.peg.or!(pegged.peg.literal!("*"), pegged.peg.literal!("%"), pegged.peg.literal!("/")), MultiplicativeExpression))), name ~ ".MultiplicativeExpression")(p);
    }

    static TParseTree MultiplicativeExpression(string s)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, CastExpression, pegged.peg.zeroOrMore!(pegged.peg.spaceAnd!(Spacing, pegged.peg.or!(pegged.peg.literal!("*"), pegged.peg.literal!("%"), pegged.peg.literal!("/")), MultiplicativeExpression))), name ~ ".MultiplicativeExpression")(TParseTree("", false,[], s));
    }

    static TParseTree AdditiveExpression(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, MultiplicativeExpression, pegged.peg.zeroOrMore!(pegged.peg.spaceAnd!(Spacing, pegged.peg.or!(pegged.peg.literal!("-"), pegged.peg.literal!("+")), AdditiveExpression))), name ~ ".AdditiveExpression")(p);
    }

    static TParseTree AdditiveExpression(string s)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, MultiplicativeExpression, pegged.peg.zeroOrMore!(pegged.peg.spaceAnd!(Spacing, pegged.peg.or!(pegged.peg.literal!("-"), pegged.peg.literal!("+")), AdditiveExpression))), name ~ ".AdditiveExpression")(TParseTree("", false,[], s));
    }

    static TParseTree ShiftExpression(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, AdditiveExpression, pegged.peg.zeroOrMore!(pegged.peg.spaceAnd!(Spacing, pegged.peg.keywords!("<<", ">>"), ShiftExpression))), name ~ ".ShiftExpression")(p);
    }

    static TParseTree ShiftExpression(string s)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, AdditiveExpression, pegged.peg.zeroOrMore!(pegged.peg.spaceAnd!(Spacing, pegged.peg.keywords!("<<", ">>"), ShiftExpression))), name ~ ".ShiftExpression")(TParseTree("", false,[], s));
    }

    static TParseTree RelationalExpression(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, ShiftExpression, pegged.peg.zeroOrMore!(pegged.peg.spaceAnd!(Spacing, pegged.peg.keywords!("<=", ">=", "<", ">"), RelationalExpression))), name ~ ".RelationalExpression")(p);
    }

    static TParseTree RelationalExpression(string s)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, ShiftExpression, pegged.peg.zeroOrMore!(pegged.peg.spaceAnd!(Spacing, pegged.peg.keywords!("<=", ">=", "<", ">"), RelationalExpression))), name ~ ".RelationalExpression")(TParseTree("", false,[], s));
    }

    static TParseTree EqualityExpression(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, RelationalExpression, pegged.peg.zeroOrMore!(pegged.peg.spaceAnd!(Spacing, pegged.peg.keywords!("==", "!="), EqualityExpression))), name ~ ".EqualityExpression")(p);
    }

    static TParseTree EqualityExpression(string s)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, RelationalExpression, pegged.peg.zeroOrMore!(pegged.peg.spaceAnd!(Spacing, pegged.peg.keywords!("==", "!="), EqualityExpression))), name ~ ".EqualityExpression")(TParseTree("", false,[], s));
    }

    static TParseTree ANDExpression(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, EqualityExpression, pegged.peg.zeroOrMore!(pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("&"), ANDExpression))), name ~ ".ANDExpression")(p);
    }

    static TParseTree ANDExpression(string s)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, EqualityExpression, pegged.peg.zeroOrMore!(pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("&"), ANDExpression))), name ~ ".ANDExpression")(TParseTree("", false,[], s));
    }

    static TParseTree ExclusiveORExpression(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, ANDExpression, pegged.peg.zeroOrMore!(pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("^"), ExclusiveORExpression))), name ~ ".ExclusiveORExpression")(p);
    }

    static TParseTree ExclusiveORExpression(string s)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, ANDExpression, pegged.peg.zeroOrMore!(pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("^"), ExclusiveORExpression))), name ~ ".ExclusiveORExpression")(TParseTree("", false,[], s));
    }

    static TParseTree InclusiveORExpression(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, ExclusiveORExpression, pegged.peg.zeroOrMore!(pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("|"), InclusiveORExpression))), name ~ ".InclusiveORExpression")(p);
    }

    static TParseTree InclusiveORExpression(string s)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, ExclusiveORExpression, pegged.peg.zeroOrMore!(pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("|"), InclusiveORExpression))), name ~ ".InclusiveORExpression")(TParseTree("", false,[], s));
    }

    static TParseTree LogicalANDExpression(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, InclusiveORExpression, pegged.peg.zeroOrMore!(pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("&&"), LogicalANDExpression))), name ~ ".LogicalANDExpression")(p);
    }

    static TParseTree LogicalANDExpression(string s)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, InclusiveORExpression, pegged.peg.zeroOrMore!(pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("&&"), LogicalANDExpression))), name ~ ".LogicalANDExpression")(TParseTree("", false,[], s));
    }

    static TParseTree LogicalORExpression(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, LogicalANDExpression, pegged.peg.zeroOrMore!(pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("||"), LogicalORExpression))), name ~ ".LogicalORExpression")(p);
    }

    static TParseTree LogicalORExpression(string s)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, LogicalANDExpression, pegged.peg.zeroOrMore!(pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("||"), LogicalORExpression))), name ~ ".LogicalORExpression")(TParseTree("", false,[], s));
    }

    static TParseTree ConditionalExpression(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, LogicalORExpression, pegged.peg.option!(pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("?"), Expression, pegged.peg.literal!(":"), ConditionalExpression))), name ~ ".ConditionalExpression")(p);
    }

    static TParseTree ConditionalExpression(string s)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, LogicalORExpression, pegged.peg.option!(pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("?"), Expression, pegged.peg.literal!(":"), ConditionalExpression))), name ~ ".ConditionalExpression")(TParseTree("", false,[], s));
    }

    static TParseTree AssignmentExpression(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.or!(pegged.peg.spaceAnd!(Spacing, UnaryExpression, AssignmentOperator, AssignmentExpression), ConditionalExpression), name ~ ".AssignmentExpression")(p);
    }

    static TParseTree AssignmentExpression(string s)
    {
        return pegged.peg.named!(pegged.peg.or!(pegged.peg.spaceAnd!(Spacing, UnaryExpression, AssignmentOperator, AssignmentExpression), ConditionalExpression), name ~ ".AssignmentExpression")(TParseTree("", false,[], s));
    }

    static TParseTree AssignmentOperator(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.keywords!("=", "*=", "/=", "%=", "+=", "-=", "<<=", ">>=", "&=", "^=", "|="), name ~ ".AssignmentOperator")(p);
    }

    static TParseTree AssignmentOperator(string s)
    {
        return pegged.peg.named!(pegged.peg.keywords!("=", "*=", "/=", "%=", "+=", "-=", "<<=", ">>=", "&=", "^=", "|="), name ~ ".AssignmentOperator")(TParseTree("", false,[], s));
    }

    static TParseTree Expression(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, AssignmentExpression, pegged.peg.zeroOrMore!(pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!(","), AssignmentExpression))), name ~ ".Expression")(p);
    }

    static TParseTree Expression(string s)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, AssignmentExpression, pegged.peg.zeroOrMore!(pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!(","), AssignmentExpression))), name ~ ".Expression")(TParseTree("", false,[], s));
    }

    static TParseTree ConstantExpression(TParseTree p)
    {
        return pegged.peg.named!(ConditionalExpression, name ~ ".ConstantExpression")(p);
    }

    static TParseTree ConstantExpression(string s)
    {
        return pegged.peg.named!(ConditionalExpression, name ~ ".ConstantExpression")(TParseTree("", false,[], s));
    }

    static TParseTree Declaration(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, DeclarationSpecifiers, pegged.peg.option!(InitDeclaratorList), pegged.peg.literal!(";")), name ~ ".Declaration")(p);
    }

    static TParseTree Declaration(string s)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, DeclarationSpecifiers, pegged.peg.option!(InitDeclaratorList), pegged.peg.literal!(";")), name ~ ".Declaration")(TParseTree("", false,[], s));
    }

    static TParseTree DeclarationSpecifiers(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, pegged.peg.or!(StorageClassSpecifier, TypeSpecifier, TypeQualifier), pegged.peg.option!(DeclarationSpecifiers)), name ~ ".DeclarationSpecifiers")(p);
    }

    static TParseTree DeclarationSpecifiers(string s)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, pegged.peg.or!(StorageClassSpecifier, TypeSpecifier, TypeQualifier), pegged.peg.option!(DeclarationSpecifiers)), name ~ ".DeclarationSpecifiers")(TParseTree("", false,[], s));
    }

    static TParseTree InitDeclaratorList(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, InitDeclarator, pegged.peg.zeroOrMore!(pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!(","), InitDeclarator))), name ~ ".InitDeclaratorList")(p);
    }

    static TParseTree InitDeclaratorList(string s)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, InitDeclarator, pegged.peg.zeroOrMore!(pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!(","), InitDeclarator))), name ~ ".InitDeclaratorList")(TParseTree("", false,[], s));
    }

    static TParseTree InitDeclarator(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, Declarator, pegged.peg.option!(pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("="), Initializer))), name ~ ".InitDeclarator")(p);
    }

    static TParseTree InitDeclarator(string s)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, Declarator, pegged.peg.option!(pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("="), Initializer))), name ~ ".InitDeclarator")(TParseTree("", false,[], s));
    }

    static TParseTree StorageClassSpecifier(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.keywords!("typedef", "extern", "static", "auto", "register"), name ~ ".StorageClassSpecifier")(p);
    }

    static TParseTree StorageClassSpecifier(string s)
    {
        return pegged.peg.named!(pegged.peg.keywords!("typedef", "extern", "static", "auto", "register"), name ~ ".StorageClassSpecifier")(TParseTree("", false,[], s));
    }

    static TParseTree TypeSpecifier(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.or!(pegged.peg.literal!("void"), pegged.peg.literal!("char"), pegged.peg.literal!("short"), pegged.peg.literal!("int"), pegged.peg.literal!("long"), pegged.peg.literal!("float"), pegged.peg.literal!("double"), pegged.peg.literal!("signed"), pegged.peg.literal!("unsigned"), StructOrUnionSpecifier, EnumSpecifier), name ~ ".TypeSpecifier")(p);
    }

    static TParseTree TypeSpecifier(string s)
    {
        return pegged.peg.named!(pegged.peg.or!(pegged.peg.literal!("void"), pegged.peg.literal!("char"), pegged.peg.literal!("short"), pegged.peg.literal!("int"), pegged.peg.literal!("long"), pegged.peg.literal!("float"), pegged.peg.literal!("double"), pegged.peg.literal!("signed"), pegged.peg.literal!("unsigned"), StructOrUnionSpecifier, EnumSpecifier), name ~ ".TypeSpecifier")(TParseTree("", false,[], s));
    }

    static TParseTree StructOrUnionSpecifier(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, pegged.peg.keywords!("struct", "union"), pegged.peg.or!(pegged.peg.spaceAnd!(Spacing, Identifier, pegged.peg.option!(pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("{"), StructDeclarationList, pegged.peg.literal!("}")))), pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("{"), StructDeclarationList, pegged.peg.literal!("}")))), name ~ ".StructOrUnionSpecifier")(p);
    }

    static TParseTree StructOrUnionSpecifier(string s)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, pegged.peg.keywords!("struct", "union"), pegged.peg.or!(pegged.peg.spaceAnd!(Spacing, Identifier, pegged.peg.option!(pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("{"), StructDeclarationList, pegged.peg.literal!("}")))), pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("{"), StructDeclarationList, pegged.peg.literal!("}")))), name ~ ".StructOrUnionSpecifier")(TParseTree("", false,[], s));
    }

    static TParseTree StructDeclarationList(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.and!(StructDeclaration, pegged.peg.zeroOrMore!(pegged.peg.and!(pegged.peg.discard!(Spacing), StructDeclaration))), name ~ ".StructDeclarationList")(p);
    }

    static TParseTree StructDeclarationList(string s)
    {
        return pegged.peg.named!(pegged.peg.and!(StructDeclaration, pegged.peg.zeroOrMore!(pegged.peg.and!(pegged.peg.discard!(Spacing), StructDeclaration))), name ~ ".StructDeclarationList")(TParseTree("", false,[], s));
    }

    static TParseTree StructDeclaration(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, SpecifierQualifierList, StructDeclaratorList, pegged.peg.literal!(";")), name ~ ".StructDeclaration")(p);
    }

    static TParseTree StructDeclaration(string s)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, SpecifierQualifierList, StructDeclaratorList, pegged.peg.literal!(";")), name ~ ".StructDeclaration")(TParseTree("", false,[], s));
    }

    static TParseTree SpecifierQualifierList(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.and!(pegged.peg.or!(TypeQualifier, TypeSpecifier), pegged.peg.zeroOrMore!(pegged.peg.and!(pegged.peg.discard!(Spacing), pegged.peg.or!(TypeQualifier, TypeSpecifier)))), name ~ ".SpecifierQualifierList")(p);
    }

    static TParseTree SpecifierQualifierList(string s)
    {
        return pegged.peg.named!(pegged.peg.and!(pegged.peg.or!(TypeQualifier, TypeSpecifier), pegged.peg.zeroOrMore!(pegged.peg.and!(pegged.peg.discard!(Spacing), pegged.peg.or!(TypeQualifier, TypeSpecifier)))), name ~ ".SpecifierQualifierList")(TParseTree("", false,[], s));
    }

    static TParseTree StructDeclaratorList(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, StructDeclarator, pegged.peg.zeroOrMore!(pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!(","), StructDeclarator))), name ~ ".StructDeclaratorList")(p);
    }

    static TParseTree StructDeclaratorList(string s)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, StructDeclarator, pegged.peg.zeroOrMore!(pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!(","), StructDeclarator))), name ~ ".StructDeclaratorList")(TParseTree("", false,[], s));
    }

    static TParseTree StructDeclarator(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.or!(pegged.peg.spaceAnd!(Spacing, Declarator, pegged.peg.option!(ConstantExpression)), ConstantExpression), name ~ ".StructDeclarator")(p);
    }

    static TParseTree StructDeclarator(string s)
    {
        return pegged.peg.named!(pegged.peg.or!(pegged.peg.spaceAnd!(Spacing, Declarator, pegged.peg.option!(ConstantExpression)), ConstantExpression), name ~ ".StructDeclarator")(TParseTree("", false,[], s));
    }

    static TParseTree EnumSpecifier(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("enum"), pegged.peg.or!(pegged.peg.spaceAnd!(Spacing, Identifier, pegged.peg.option!(pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("{"), EnumeratorList, pegged.peg.literal!("}")))), pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("{"), EnumeratorList, pegged.peg.literal!("}")))), name ~ ".EnumSpecifier")(p);
    }

    static TParseTree EnumSpecifier(string s)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("enum"), pegged.peg.or!(pegged.peg.spaceAnd!(Spacing, Identifier, pegged.peg.option!(pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("{"), EnumeratorList, pegged.peg.literal!("}")))), pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("{"), EnumeratorList, pegged.peg.literal!("}")))), name ~ ".EnumSpecifier")(TParseTree("", false,[], s));
    }

    static TParseTree EnumeratorList(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, Enumerator, pegged.peg.zeroOrMore!(pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!(","), Enumerator))), name ~ ".EnumeratorList")(p);
    }

    static TParseTree EnumeratorList(string s)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, Enumerator, pegged.peg.zeroOrMore!(pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!(","), Enumerator))), name ~ ".EnumeratorList")(TParseTree("", false,[], s));
    }

    static TParseTree Enumerator(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, EnumerationConstant, pegged.peg.option!(pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("="), ConstantExpression))), name ~ ".Enumerator")(p);
    }

    static TParseTree Enumerator(string s)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, EnumerationConstant, pegged.peg.option!(pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("="), ConstantExpression))), name ~ ".Enumerator")(TParseTree("", false,[], s));
    }

    static TParseTree EnumerationConstant(TParseTree p)
    {
        return pegged.peg.named!(Identifier, name ~ ".EnumerationConstant")(p);
    }

    static TParseTree EnumerationConstant(string s)
    {
        return pegged.peg.named!(Identifier, name ~ ".EnumerationConstant")(TParseTree("", false,[], s));
    }

    static TParseTree TypeQualifier(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.keywords!("const", "volatile"), name ~ ".TypeQualifier")(p);
    }

    static TParseTree TypeQualifier(string s)
    {
        return pegged.peg.named!(pegged.peg.keywords!("const", "volatile"), name ~ ".TypeQualifier")(TParseTree("", false,[], s));
    }

    static TParseTree Declarator(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, pegged.peg.option!(Pointer), DirectDeclarator), name ~ ".Declarator")(p);
    }

    static TParseTree Declarator(string s)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, pegged.peg.option!(Pointer), DirectDeclarator), name ~ ".Declarator")(TParseTree("", false,[], s));
    }

    static TParseTree DirectDeclarator(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, pegged.peg.or!(Identifier, pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("("), Declarator, pegged.peg.literal!(")"))), pegged.peg.zeroOrMore!(pegged.peg.or!(pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("["), pegged.peg.literal!("]")), pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("["), ConstantExpression, pegged.peg.literal!("]")), pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("("), pegged.peg.literal!(")")), pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("("), ParameterTypeList, pegged.peg.literal!(")")), pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("("), IdentifierList, pegged.peg.literal!(")"))))), name ~ ".DirectDeclarator")(p);
    }

    static TParseTree DirectDeclarator(string s)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, pegged.peg.or!(Identifier, pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("("), Declarator, pegged.peg.literal!(")"))), pegged.peg.zeroOrMore!(pegged.peg.or!(pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("["), pegged.peg.literal!("]")), pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("["), ConstantExpression, pegged.peg.literal!("]")), pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("("), pegged.peg.literal!(")")), pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("("), ParameterTypeList, pegged.peg.literal!(")")), pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("("), IdentifierList, pegged.peg.literal!(")"))))), name ~ ".DirectDeclarator")(TParseTree("", false,[], s));
    }

    static TParseTree Pointer(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.zeroOrMore!(pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("*"), pegged.peg.zeroOrMore!(TypeQualifier))), name ~ ".Pointer")(p);
    }

    static TParseTree Pointer(string s)
    {
        return pegged.peg.named!(pegged.peg.zeroOrMore!(pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("*"), pegged.peg.zeroOrMore!(TypeQualifier))), name ~ ".Pointer")(TParseTree("", false,[], s));
    }

    static TParseTree TypeQualifierList(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.and!(TypeQualifier, pegged.peg.zeroOrMore!(pegged.peg.and!(pegged.peg.discard!(Spacing), TypeQualifier))), name ~ ".TypeQualifierList")(p);
    }

    static TParseTree TypeQualifierList(string s)
    {
        return pegged.peg.named!(pegged.peg.and!(TypeQualifier, pegged.peg.zeroOrMore!(pegged.peg.and!(pegged.peg.discard!(Spacing), TypeQualifier))), name ~ ".TypeQualifierList")(TParseTree("", false,[], s));
    }

    static TParseTree ParameterTypeList(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, ParameterList, pegged.peg.option!(pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!(","), pegged.peg.literal!("...")))), name ~ ".ParameterTypeList")(p);
    }

    static TParseTree ParameterTypeList(string s)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, ParameterList, pegged.peg.option!(pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!(","), pegged.peg.literal!("...")))), name ~ ".ParameterTypeList")(TParseTree("", false,[], s));
    }

    static TParseTree ParameterList(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, ParameterDeclaration, pegged.peg.zeroOrMore!(pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!(","), ParameterDeclaration))), name ~ ".ParameterList")(p);
    }

    static TParseTree ParameterList(string s)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, ParameterDeclaration, pegged.peg.zeroOrMore!(pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!(","), ParameterDeclaration))), name ~ ".ParameterList")(TParseTree("", false,[], s));
    }

    static TParseTree ParameterDeclaration(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, DeclarationSpecifiers, pegged.peg.option!(pegged.peg.or!(Declarator, AbstractDeclarator))), name ~ ".ParameterDeclaration")(p);
    }

    static TParseTree ParameterDeclaration(string s)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, DeclarationSpecifiers, pegged.peg.option!(pegged.peg.or!(Declarator, AbstractDeclarator))), name ~ ".ParameterDeclaration")(TParseTree("", false,[], s));
    }

    static TParseTree IdentifierList(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, Identifier, pegged.peg.zeroOrMore!(pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!(","), Identifier))), name ~ ".IdentifierList")(p);
    }

    static TParseTree IdentifierList(string s)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, Identifier, pegged.peg.zeroOrMore!(pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!(","), Identifier))), name ~ ".IdentifierList")(TParseTree("", false,[], s));
    }

    static TParseTree TypeName(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, SpecifierQualifierList, pegged.peg.option!(AbstractDeclarator)), name ~ ".TypeName")(p);
    }

    static TParseTree TypeName(string s)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, SpecifierQualifierList, pegged.peg.option!(AbstractDeclarator)), name ~ ".TypeName")(TParseTree("", false,[], s));
    }

    static TParseTree AbstractDeclarator(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.or!(pegged.peg.spaceAnd!(Spacing, Pointer, DirectAbstractDeclarator), DirectAbstractDeclarator, Pointer), name ~ ".AbstractDeclarator")(p);
    }

    static TParseTree AbstractDeclarator(string s)
    {
        return pegged.peg.named!(pegged.peg.or!(pegged.peg.spaceAnd!(Spacing, Pointer, DirectAbstractDeclarator), DirectAbstractDeclarator, Pointer), name ~ ".AbstractDeclarator")(TParseTree("", false,[], s));
    }

    static TParseTree DirectAbstractDeclarator(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, pegged.peg.or!(pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("("), AbstractDeclarator, pegged.peg.literal!(")")), pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("["), pegged.peg.literal!("]")), pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("["), ConstantExpression, pegged.peg.literal!("]")), pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("("), pegged.peg.literal!(")")), pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("("), ParameterTypeList, pegged.peg.literal!(")"))), pegged.peg.zeroOrMore!(pegged.peg.or!(pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("["), pegged.peg.literal!("]")), pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("["), ConstantExpression, pegged.peg.literal!("]")), pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("("), pegged.peg.literal!(")")), pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("("), ParameterTypeList, pegged.peg.literal!(")"))))), name ~ ".DirectAbstractDeclarator")(p);
    }

    static TParseTree DirectAbstractDeclarator(string s)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, pegged.peg.or!(pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("("), AbstractDeclarator, pegged.peg.literal!(")")), pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("["), pegged.peg.literal!("]")), pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("["), ConstantExpression, pegged.peg.literal!("]")), pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("("), pegged.peg.literal!(")")), pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("("), ParameterTypeList, pegged.peg.literal!(")"))), pegged.peg.zeroOrMore!(pegged.peg.or!(pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("["), pegged.peg.literal!("]")), pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("["), ConstantExpression, pegged.peg.literal!("]")), pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("("), pegged.peg.literal!(")")), pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("("), ParameterTypeList, pegged.peg.literal!(")"))))), name ~ ".DirectAbstractDeclarator")(TParseTree("", false,[], s));
    }

    static TParseTree TypedefName(TParseTree p)
    {
        return pegged.peg.named!(Identifier, name ~ ".TypedefName")(p);
    }

    static TParseTree TypedefName(string s)
    {
        return pegged.peg.named!(Identifier, name ~ ".TypedefName")(TParseTree("", false,[], s));
    }

    static TParseTree Initializer(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.or!(AssignmentExpression, pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("{"), InitializerList, pegged.peg.option!(pegged.peg.literal!(",")), pegged.peg.literal!("}"))), name ~ ".Initializer")(p);
    }

    static TParseTree Initializer(string s)
    {
        return pegged.peg.named!(pegged.peg.or!(AssignmentExpression, pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("{"), InitializerList, pegged.peg.option!(pegged.peg.literal!(",")), pegged.peg.literal!("}"))), name ~ ".Initializer")(TParseTree("", false,[], s));
    }

    static TParseTree InitializerList(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, Initializer, pegged.peg.zeroOrMore!(pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!(","), Initializer))), name ~ ".InitializerList")(p);
    }

    static TParseTree InitializerList(string s)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, Initializer, pegged.peg.zeroOrMore!(pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!(","), Initializer))), name ~ ".InitializerList")(TParseTree("", false,[], s));
    }

    static TParseTree Statement(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.or!(LabeledStatement, CompoundStatement, ExpressionStatement, IfStatement, SwitchStatement, IterationStatement, GotoStatement, ContinueStatement, BreakStatement, ReturnStatement), name ~ ".Statement")(p);
    }

    static TParseTree Statement(string s)
    {
        return pegged.peg.named!(pegged.peg.or!(LabeledStatement, CompoundStatement, ExpressionStatement, IfStatement, SwitchStatement, IterationStatement, GotoStatement, ContinueStatement, BreakStatement, ReturnStatement), name ~ ".Statement")(TParseTree("", false,[], s));
    }

    static TParseTree LabeledStatement(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.or!(pegged.peg.spaceAnd!(Spacing, Identifier, pegged.peg.literal!(":"), Statement), pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("case"), ConstantExpression, pegged.peg.literal!(":"), Statement), pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("default"), pegged.peg.literal!(":"), Statement)), name ~ ".LabeledStatement")(p);
    }

    static TParseTree LabeledStatement(string s)
    {
        return pegged.peg.named!(pegged.peg.or!(pegged.peg.spaceAnd!(Spacing, Identifier, pegged.peg.literal!(":"), Statement), pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("case"), ConstantExpression, pegged.peg.literal!(":"), Statement), pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("default"), pegged.peg.literal!(":"), Statement)), name ~ ".LabeledStatement")(TParseTree("", false,[], s));
    }

    static TParseTree CompoundStatement(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.or!(pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("{"), pegged.peg.literal!("}")), pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("{"), DeclarationList, pegged.peg.literal!("}")), pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("{"), StatementList, pegged.peg.literal!("}")), pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("{"), DeclarationList, StatementList, pegged.peg.literal!("}"))), name ~ ".CompoundStatement")(p);
    }

    static TParseTree CompoundStatement(string s)
    {
        return pegged.peg.named!(pegged.peg.or!(pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("{"), pegged.peg.literal!("}")), pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("{"), DeclarationList, pegged.peg.literal!("}")), pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("{"), StatementList, pegged.peg.literal!("}")), pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("{"), DeclarationList, StatementList, pegged.peg.literal!("}"))), name ~ ".CompoundStatement")(TParseTree("", false,[], s));
    }

    static TParseTree DeclarationList(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.and!(Declaration, pegged.peg.zeroOrMore!(pegged.peg.and!(pegged.peg.discard!(Spacing), Declaration))), name ~ ".DeclarationList")(p);
    }

    static TParseTree DeclarationList(string s)
    {
        return pegged.peg.named!(pegged.peg.and!(Declaration, pegged.peg.zeroOrMore!(pegged.peg.and!(pegged.peg.discard!(Spacing), Declaration))), name ~ ".DeclarationList")(TParseTree("", false,[], s));
    }

    static TParseTree StatementList(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.and!(Statement, pegged.peg.zeroOrMore!(pegged.peg.and!(pegged.peg.discard!(Spacing), Statement))), name ~ ".StatementList")(p);
    }

    static TParseTree StatementList(string s)
    {
        return pegged.peg.named!(pegged.peg.and!(Statement, pegged.peg.zeroOrMore!(pegged.peg.and!(pegged.peg.discard!(Spacing), Statement))), name ~ ".StatementList")(TParseTree("", false,[], s));
    }

    static TParseTree ExpressionStatement(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, pegged.peg.option!(Expression), pegged.peg.literal!(";")), name ~ ".ExpressionStatement")(p);
    }

    static TParseTree ExpressionStatement(string s)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, pegged.peg.option!(Expression), pegged.peg.literal!(";")), name ~ ".ExpressionStatement")(TParseTree("", false,[], s));
    }

    static TParseTree IfStatement(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("if"), pegged.peg.literal!("("), Expression, pegged.peg.literal!(")"), Statement, pegged.peg.option!(pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("else"), Statement))), name ~ ".IfStatement")(p);
    }

    static TParseTree IfStatement(string s)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("if"), pegged.peg.literal!("("), Expression, pegged.peg.literal!(")"), Statement, pegged.peg.option!(pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("else"), Statement))), name ~ ".IfStatement")(TParseTree("", false,[], s));
    }

    static TParseTree SwitchStatement(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("switch"), pegged.peg.literal!("("), Expression, pegged.peg.literal!(")"), Statement), name ~ ".SwitchStatement")(p);
    }

    static TParseTree SwitchStatement(string s)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("switch"), pegged.peg.literal!("("), Expression, pegged.peg.literal!(")"), Statement), name ~ ".SwitchStatement")(TParseTree("", false,[], s));
    }

    static TParseTree IterationStatement(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.or!(WhileStatement, DoStatement, ForStatement), name ~ ".IterationStatement")(p);
    }

    static TParseTree IterationStatement(string s)
    {
        return pegged.peg.named!(pegged.peg.or!(WhileStatement, DoStatement, ForStatement), name ~ ".IterationStatement")(TParseTree("", false,[], s));
    }

    static TParseTree WhileStatement(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("while"), pegged.peg.literal!("("), Expression, pegged.peg.literal!(")"), Statement), name ~ ".WhileStatement")(p);
    }

    static TParseTree WhileStatement(string s)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("while"), pegged.peg.literal!("("), Expression, pegged.peg.literal!(")"), Statement), name ~ ".WhileStatement")(TParseTree("", false,[], s));
    }

    static TParseTree DoStatement(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("do"), Statement, pegged.peg.literal!("while"), pegged.peg.literal!("("), Expression, pegged.peg.literal!(")"), pegged.peg.literal!(";")), name ~ ".DoStatement")(p);
    }

    static TParseTree DoStatement(string s)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("do"), Statement, pegged.peg.literal!("while"), pegged.peg.literal!("("), Expression, pegged.peg.literal!(")"), pegged.peg.literal!(";")), name ~ ".DoStatement")(TParseTree("", false,[], s));
    }

    static TParseTree ForStatement(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("for"), pegged.peg.literal!("("), pegged.peg.option!(Expression), pegged.peg.literal!(";"), pegged.peg.option!(Expression), pegged.peg.literal!(";"), pegged.peg.option!(Expression), pegged.peg.literal!(")"), Statement), name ~ ".ForStatement")(p);
    }

    static TParseTree ForStatement(string s)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("for"), pegged.peg.literal!("("), pegged.peg.option!(Expression), pegged.peg.literal!(";"), pegged.peg.option!(Expression), pegged.peg.literal!(";"), pegged.peg.option!(Expression), pegged.peg.literal!(")"), Statement), name ~ ".ForStatement")(TParseTree("", false,[], s));
    }

    static TParseTree GotoStatement(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("goto"), Identifier, pegged.peg.literal!(";")), name ~ ".GotoStatement")(p);
    }

    static TParseTree GotoStatement(string s)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("goto"), Identifier, pegged.peg.literal!(";")), name ~ ".GotoStatement")(TParseTree("", false,[], s));
    }

    static TParseTree ContinueStatement(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("continue"), pegged.peg.literal!(";")), name ~ ".ContinueStatement")(p);
    }

    static TParseTree ContinueStatement(string s)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("continue"), pegged.peg.literal!(";")), name ~ ".ContinueStatement")(TParseTree("", false,[], s));
    }

    static TParseTree BreakStatement(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("break"), pegged.peg.literal!(";")), name ~ ".BreakStatement")(p);
    }

    static TParseTree BreakStatement(string s)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, pegged.peg.literal!("break"), pegged.peg.literal!(";")), name ~ ".BreakStatement")(TParseTree("", false,[], s));
    }

    static TParseTree ReturnStatement(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, Return, pegged.peg.option!(Expression), pegged.peg.discard!(pegged.peg.literal!(";"))), name ~ ".ReturnStatement")(p);
    }

    static TParseTree ReturnStatement(string s)
    {
        return pegged.peg.named!(pegged.peg.spaceAnd!(Spacing, Return, pegged.peg.option!(Expression), pegged.peg.discard!(pegged.peg.literal!(";"))), name ~ ".ReturnStatement")(TParseTree("", false,[], s));
    }

    static TParseTree Return(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.literal!("return"), name ~ ".Return")(p);
    }

    static TParseTree Return(string s)
    {
        return pegged.peg.named!(pegged.peg.literal!("return"), name ~ ".Return")(TParseTree("", false,[], s));
    }

    static TParseTree Identifier(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.fuse!(pegged.peg.and!(pegged.peg.negLookahead!(Keyword), pegged.peg.or!(pegged.peg.charRange!('a', 'z'), pegged.peg.charRange!('A', 'Z'), pegged.peg.literal!("_")), pegged.peg.zeroOrMore!(pegged.peg.or!(pegged.peg.charRange!('a', 'z'), pegged.peg.charRange!('A', 'Z'), pegged.peg.charRange!('0', '9'), pegged.peg.literal!("_"))))), name ~ ".Identifier")(p);
    }

    static TParseTree Identifier(string s)
    {
        return pegged.peg.named!(pegged.peg.fuse!(pegged.peg.and!(pegged.peg.negLookahead!(Keyword), pegged.peg.or!(pegged.peg.charRange!('a', 'z'), pegged.peg.charRange!('A', 'Z'), pegged.peg.literal!("_")), pegged.peg.zeroOrMore!(pegged.peg.or!(pegged.peg.charRange!('a', 'z'), pegged.peg.charRange!('A', 'Z'), pegged.peg.charRange!('0', '9'), pegged.peg.literal!("_"))))), name ~ ".Identifier")(TParseTree("", false,[], s));
    }

    static TParseTree Keyword(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.keywords!("auto", "break", "case", "char", "const", "continue", "default", "double", "do", "else", "enum", "extern", "float", "for", "goto", "if", "inline", "int", "long", "register", "restrict", "return", "short", "signed", "sizeof", "static", "struct", "switch", "typedef", "union", "unsigned", "void", "volatile", "while", "_Bool", "_Complex", "_Imaginary"), name ~ ".Keyword")(p);
    }

    static TParseTree Keyword(string s)
    {
        return pegged.peg.named!(pegged.peg.keywords!("auto", "break", "case", "char", "const", "continue", "default", "double", "do", "else", "enum", "extern", "float", "for", "goto", "if", "inline", "int", "long", "register", "restrict", "return", "short", "signed", "sizeof", "static", "struct", "switch", "typedef", "union", "unsigned", "void", "volatile", "while", "_Bool", "_Complex", "_Imaginary"), name ~ ".Keyword")(TParseTree("", false,[], s));
    }

    static TParseTree Spacing(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.fuse!(pegged.peg.zeroOrMore!(pegged.peg.or!(Space, Blank, EOL, Comment))), name ~ ".Spacing")(p);
    }

    static TParseTree Spacing(string s)
    {
        return pegged.peg.named!(pegged.peg.fuse!(pegged.peg.zeroOrMore!(pegged.peg.or!(Space, Blank, EOL, Comment))), name ~ ".Spacing")(TParseTree("", false,[], s));
    }

    static TParseTree Comment(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.fuse!(pegged.peg.and!(pegged.peg.literal!("//"), pegged.peg.zeroOrMore!(pegged.peg.and!(pegged.peg.negLookahead!(EOL), pegged.peg.any)), EOL)), name ~ ".Comment")(p);
    }

    static TParseTree Comment(string s)
    {
        return pegged.peg.named!(pegged.peg.fuse!(pegged.peg.and!(pegged.peg.literal!("//"), pegged.peg.zeroOrMore!(pegged.peg.and!(pegged.peg.negLookahead!(EOL), pegged.peg.any)), EOL)), name ~ ".Comment")(TParseTree("", false,[], s));
    }

    static TParseTree StringLiteral(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.fuse!(pegged.peg.and!(DoubleQuote, pegged.peg.zeroOrMore!(DQChar), DoubleQuote)), name ~ ".StringLiteral")(p);
    }

    static TParseTree StringLiteral(string s)
    {
        return pegged.peg.named!(pegged.peg.fuse!(pegged.peg.and!(DoubleQuote, pegged.peg.zeroOrMore!(DQChar), DoubleQuote)), name ~ ".StringLiteral")(TParseTree("", false,[], s));
    }

    static TParseTree DQChar(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.or!(EscapeSequence, pegged.peg.and!(pegged.peg.negLookahead!(DoubleQuote), pegged.peg.any)), name ~ ".DQChar")(p);
    }

    static TParseTree DQChar(string s)
    {
        return pegged.peg.named!(pegged.peg.or!(EscapeSequence, pegged.peg.and!(pegged.peg.negLookahead!(DoubleQuote), pegged.peg.any)), name ~ ".DQChar")(TParseTree("", false,[], s));
    }

    static TParseTree EscapeSequence(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.fuse!(pegged.peg.and!(BackSlash, pegged.peg.or!(Quote, DoubleQuote, BackSlash, pegged.peg.or!(pegged.peg.literal!("a"), pegged.peg.literal!("b"), pegged.peg.literal!("f"), pegged.peg.literal!("n"), pegged.peg.literal!("r"), pegged.peg.literal!("t"), pegged.peg.literal!("v"))))), name ~ ".EscapeSequence")(p);
    }

    static TParseTree EscapeSequence(string s)
    {
        return pegged.peg.named!(pegged.peg.fuse!(pegged.peg.and!(BackSlash, pegged.peg.or!(Quote, DoubleQuote, BackSlash, pegged.peg.or!(pegged.peg.literal!("a"), pegged.peg.literal!("b"), pegged.peg.literal!("f"), pegged.peg.literal!("n"), pegged.peg.literal!("r"), pegged.peg.literal!("t"), pegged.peg.literal!("v"))))), name ~ ".EscapeSequence")(TParseTree("", false,[], s));
    }

    static TParseTree CharLiteral(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.fuse!(pegged.peg.and!(Quote, pegged.peg.and!(pegged.peg.negLookahead!(Quote), pegged.peg.or!(EscapeSequence, pegged.peg.any)), Quote)), name ~ ".CharLiteral")(p);
    }

    static TParseTree CharLiteral(string s)
    {
        return pegged.peg.named!(pegged.peg.fuse!(pegged.peg.and!(Quote, pegged.peg.and!(pegged.peg.negLookahead!(Quote), pegged.peg.or!(EscapeSequence, pegged.peg.any)), Quote)), name ~ ".CharLiteral")(TParseTree("", false,[], s));
    }

    static TParseTree IntegerLiteral(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.fuse!(pegged.peg.and!(pegged.peg.option!(Sign), Integer, pegged.peg.option!(IntegerSuffix))), name ~ ".IntegerLiteral")(p);
    }

    static TParseTree IntegerLiteral(string s)
    {
        return pegged.peg.named!(pegged.peg.fuse!(pegged.peg.and!(pegged.peg.option!(Sign), Integer, pegged.peg.option!(IntegerSuffix))), name ~ ".IntegerLiteral")(TParseTree("", false,[], s));
    }

    static TParseTree Integer(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.fuse!(pegged.peg.oneOrMore!(Digit)), name ~ ".Integer")(p);
    }

    static TParseTree Integer(string s)
    {
        return pegged.peg.named!(pegged.peg.fuse!(pegged.peg.oneOrMore!(Digit)), name ~ ".Integer")(TParseTree("", false,[], s));
    }

    static TParseTree IntegerSuffix(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.keywords!("Lu", "LU", "uL", "UL", "L", "u", "U"), name ~ ".IntegerSuffix")(p);
    }

    static TParseTree IntegerSuffix(string s)
    {
        return pegged.peg.named!(pegged.peg.keywords!("Lu", "LU", "uL", "UL", "L", "u", "U"), name ~ ".IntegerSuffix")(TParseTree("", false,[], s));
    }

    static TParseTree FloatLiteral(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.fuse!(pegged.peg.and!(pegged.peg.option!(Sign), Integer, pegged.peg.literal!("."), pegged.peg.option!(Integer), pegged.peg.option!(pegged.peg.and!(pegged.peg.keywords!("e", "E"), pegged.peg.option!(Sign), Integer)))), name ~ ".FloatLiteral")(p);
    }

    static TParseTree FloatLiteral(string s)
    {
        return pegged.peg.named!(pegged.peg.fuse!(pegged.peg.and!(pegged.peg.option!(Sign), Integer, pegged.peg.literal!("."), pegged.peg.option!(Integer), pegged.peg.option!(pegged.peg.and!(pegged.peg.keywords!("e", "E"), pegged.peg.option!(Sign), Integer)))), name ~ ".FloatLiteral")(TParseTree("", false,[], s));
    }

    static TParseTree Sign(TParseTree p)
    {
        return pegged.peg.named!(pegged.peg.keywords!("-", "+"), name ~ ".Sign")(p);
    }

    static TParseTree Sign(string s)
    {
        return pegged.peg.named!(pegged.peg.keywords!("-", "+"), name ~ ".Sign")(TParseTree("", false,[], s));
    }

    static TParseTree opCall(TParseTree p)
    {
        TParseTree result = decimateTree(TranslationUnit(p));
        result.children = [result];
        result.name = "C";
        return result;
    }

    static TParseTree opCall(string input)
    {
        return C(TParseTree(``, false, [], input, 0, 0));
    }
    }
}

alias GenericC!(ParseTree).C C;

