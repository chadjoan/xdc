module grammars.testGrammar;

enum string testGrammar = ` 
TestGrammar:
Root < A B*
A <- 'a'
B <- 'b'
`;