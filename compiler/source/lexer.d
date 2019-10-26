module lexer;

import pegged.grammar;

public:
ParseTree lexDocument(string document)
{
    return SCLL(document);
}

private:
mixin(grammar(`
SCLL:
    Document < ModuleDeclaration? Definition* endOfInput

    Spacing <~ (blank / SingleLineComment / MultiLineComment)*
    SingleLineComment <~ "//" (!eol .)*
    MultiLineComment <~ "/*" (!"*/" .)* "*/"

    ModuleDeclaration < "module" PathIdentifier ";"
    Definition < InterfaceDefinition / MethodDeclaration / StructDeclaration / GlobalDeclaration

    InterfaceDefinition <
        "interface" Identifier
        "{"
            (MethodDefinition ";")*
        "}"
    MethodDefinition < Identifier Identifier "(" ParameterList? ")"
    ParameterList < Parameter ("," Parameter)*
    Parameter < Identifier Identifier

    MethodDeclaration <
        MethodDefinition
        "{"
            Statement*
        "}"
	
	ConstructorDeclaration <
		"new" "(" ParameterList? ")"
		"{"
			Statement*
		"}"
	
	StructDeclaration <
		"struct" Identifier
		"{"
			( VariableDeclaration ";"
			/ MethodDeclaration
			/ ConstructorDeclaration
			)*
		"}"
	VariableDeclaration < PathIdentifier Identifier

	GlobalDeclaration < PathIdentifier Identifier ';'

    Statement < 
		( CallStatement
		/ DeclaringAssignmentStatement
		/ AssignmentStatement
		) ";"

    CallStatement < PathIdentifier "(" ArgumentList? ")"
    ArgumentList < Expression ("," Expression)*

	DeclaringAssignmentStatement < PathIdentifier Identifier "=" Expression
	AssignmentStatement < PathIdentifier "=" Expression

    Expression < TerminalExpression
	TerminalExpression < ConstructionExpression / Literal
	ConstructionExpression < "new" PathIdentifier "(" ArgumentList? ")"

    Literal < Identifier / StringLiteral / NumberLiteral
    StringLiteral <~ :doublequote (!doublequote .)* :doublequote
	NumberLiteral < digit+

    PathIdentifier <- Identifier ("." Identifier)*

    Keyword <- ("module" / "interface" / "struct" / "trait" / "new") !ValidIdentifierCharacter
    Identifier <~ !Keyword !digit ValidIdentifierCharacter+
    ValidIdentifierCharacter <~ alpha / Alpha / digit
`));

unittest
{
    void assertDocumentParses(string str)()
    {
        import std.stdio : writeln;

        ParseTree parsed = lexDocument(str);
        writeln(parsed.toString());
        if (!parsed.successful)
        {
            writeln("Failed to parse: " ~ str);
            assert(false, parsed.failMsg());
        }
    }

    assertDocumentParses!``();

    assertDocumentParses!`
    `();

    assertDocumentParses!`module test;`;
    assertDocumentParses!`module moduleName;`;

    assertDocumentParses!`interface io {}`;

    assertDocumentParses!`
    module test;
    interface io1 {}
    `;

    assertDocumentParses!`
    interface a
    {
        void test();
    }`;


    assertDocumentParses!`interface a{void test(string a);}`;
    assertDocumentParses!`interface a{void test(string a, string b);}`;

    assertDocumentParses!`void main() {}`;

    assertDocumentParses!`void main() {doSomething();}`;
    assertDocumentParses!`void main() {print("");}`;
    assertDocumentParses!`void main() {print("text");}`;

    assertDocumentParses!`
    module test;

    interface io
    {
    	void write(string name);
    }

    void main()
    {
    	io.write("Hello");
    }
    `;

    assertDocumentParses!`
    module /* complete and utter bullshit */ test;
    `;

    assertDocumentParses!`
    // interface test {}
    module test;
    `;

	assertDocumentParses!`struct Test{}`;
	assertDocumentParses!`struct Test{int a;}`;
	assertDocumentParses!`struct Test{int a; Test t;}`;

	assertDocumentParses!`struct Test{void method() {}}`;
	assertDocumentParses!`struct Test{new() {}}`;

	assertDocumentParses!`struct Test{new() {t = 4;}}`;
	assertDocumentParses!`struct Test{new() {int t = 4;}}`;
	assertDocumentParses!`int wow;`;

	assertDocumentParses!`void test() {Weapon t = new Weapon();}`;

	assertDocumentParses!`struct Test{new(var test) {}}`;
}
