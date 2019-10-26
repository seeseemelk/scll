import std.stdio : writeln;
import std.file : readText, write;

import lexer;
import parser;
import validator.validator2;
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

	@P("output", 'o')
	@Description("The output file")
	string output;
}

void main()
{
	Arguments arguments = parseArguments!Arguments();

	ParseTree tree = lexDocument(arguments.file.readText());

	if (!tree.successful)
	{
		writeln("Failed to successfully parse document:");
		writeln(tree.failMsg());
		return;
	}

	Document document = Document(tree);

	scope Library library = new Library();
	LibraryDocument documentToCompile = library.addDocument(document);
	library.allPasses();

	string output = compileToLua(documentToCompile);
	writeln(output);

	if (arguments.output.length > 0)
	{
		write(arguments.output, output);
	}
}
