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
    Definition < InterfaceDefinition / MethodDeclaration

    InterfaceDefinition <
        "interface" PathIdentifier
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

    Statement < (CallStatement) ";"

    CallStatement < PathIdentifier "(" ArgumentList? ")"
    ArgumentList < Expression ("," Expression)*

    Expression < Literal

    Literal < Identifier / StringLiteral
    StringLiteral <~ :doublequote (!doublequote .)* :doublequote

    PathIdentifier <- Identifier ("." Identifier)*

    Keyword <- ("module" / "interface") !ValidIdentifierCharacter
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
    interface interface2.damn {}
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
}
