import std.stdio;
import std.file;

import lexer;
import parser;
import validator.validator;
import luacompiler;
import pegged.parser;
import clid : P = Parameter, Required, parseArguments, Description;
import clid.validate : Validate, isFile;

struct Arguments
{
	@P("file", 'f')
	@Description("The file to compile")
	@Validate!isFile
	@Required
	string file;
}

void main()
{
	Arguments arguments = parseArguments!Arguments();

	/*ParseTree tree = lexDocument(`
	module test;

    interface io
    {
    	void write(string name);
    }

    void main()
    {
    	io.write("Hello");
    }`);*/

	ParseTree tree = lexDocument(arguments.file.readText());

	if (!tree.successful)
	{
		writeln("Failed to successfully parse document:");
		writeln(tree.failMsg());
		return;
	}

	Document document = Document(tree);

	scope Library library = new Library();
	library.addDocument(document);
	library.validateDocument(document);

	writeln(compileToLua(document));
}
