module validator.validator2;

import parser;
import validator.fqn;
import validator.types;

class LibraryStructMember
{
	string name;
	Type type;
}

class LibraryStruct : Type
{
	const StructDefinition definition;
	FQN name;
	LibraryStructMember[] members;

	this(const StructDefinition definition)
	{
		this.definition = definition;
	}

	bool isPrimitive()
	{
		return false;
	}

	FQN type()
	{
		return name;
	}
}

class LibraryDocument
{
	const Document document;
	FQN name;
	LibraryStruct[] structs;

	this(const Document document)
	{
		this.document = document;
	}

	FQN childFQN(string child)
	{
		return makeFQN(name, child);
	}

	Type findType(string name)
	{
		foreach (structure; structs)
		{
			if (structure.name.parts[$-1] == name)
				return structure;
		}
		throw new Exception("Type " ~ name ~ " not found");
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
			LibraryStruct libraryStruct = new LibraryStruct(structure);
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
			foreach (structure; document.structs)
			{
				foreach (ref member; structure.definition.variables)
				{
					LibraryStructMember structMember = new LibraryStructMember();
					structMember.name = member.name;
					structMember.type = findType(member.type);
					structure.members ~= structMember;
				}
			}
		}
	}

	Type findType(const PathIdentifier identifier)
	{
		return findType(makeFQN(identifier));
	}

	Type findType(FQN fqn)
	{
		string moduleName = fqn.parts[0];
		return findDocument(moduleName).findType(fqn.parts[1]);
	}

	LibraryDocument findDocument(string moduleName)
	{
		foreach (document; _documents)
		{
			if (document.name.parts[0] == moduleName)
				return document;
		}
		throw new Exception("Module " ~ moduleName ~ " not found");
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
		LibraryDocument libraryDocument = library.addDocument(document);
		library.firstPass();
		return libraryDocument;
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