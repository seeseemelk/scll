module validator.validator2;

import parser;
import validator.fqn;
import validator.types;

class LibraryStructMember
{
	Type type;
}

class LibraryStruct
{
	FQN name;

	LibraryStructMember[] members;
}

class LibraryDocument
{
	const Document document;
	FQN name;
	LibraryStruct[] structs;

	this(const(Document) document)
	{
		this.document = document;
	}

	FQN childFQN(string child)
	{
		return makeFQN(name, child);
	}
}

class Library
{
	LibraryDocument addDocument(const ref Document document)
	{
		LibraryDocument libraryDocument = new LibraryDocument(document);
		libraryDocument.name = makeFQN(document.moduleName);

		foreach (structure; document.structs)
		{
			LibraryStruct libraryStruct = new LibraryStruct();
			libraryStruct.name = libraryDocument.childFQN(structure.name);
			libraryDocument.structs ~= libraryStruct;
		}

		_documents ~= libraryDocument;
		return libraryDocument;
	}

	void firstPass()
	{
		foreach (LibraryDocument document; _documents)
		{
			// Parse struct members and methods.
		}
	}

private:
	LibraryDocument[] _documents;
}

version (unittest)
{
	import lexer;
	import pegged.grammar;

	LibraryDocument parseDocument(string str)
	{
		Library library = new Library();
		ParseTree parsetree = lexDocument(str);
		Document document = Document(parsetree);
		return library.addDocument(document);
	}
}

unittest
{
	assert(parseDocument("module myModule;").name.toString() == "myModule", "Name was not correctly parsed");

	assert(parseDocument(`
	module myModule;
	struct Test {}
	`).structs[0].name.toString() == "myModule.Test", "Struct name was not correctly parsed");

	LibraryDocument document = parseDocument(`
	module myModule;
	struct Test {int a;}
	`);
	assert(document.structs[0].members[0].type.type().toString() == "int");
	assert(document.structs[0].members[0].type.isPrimitive());
}