/*module validator.secondpasslibrary;

import validator.firstpasslibrary;
import validator.fqn;
import validator.types;
import parser;

class NamedType
{
	Type type;
	string name;

	this(Type type, string name)
	{
		this.type = type;
		this.name = name;
	}
}

class SecondPassStruct
{
	FQN name;
	NamedType[] members;
}

class SecondPassLibrary
{
	this(const FirstPassLibrary library)
	{
		_library = library;
	}

	void addDocuments(const Document[] documents)
	{
		foreach (document; documents)
		{
			addDocument(documents);
		}
	}

	void addDocument(const ref Document document)
	{
		foreach (structure; document.structs)
		{
			SecondPassStruct newStructure = new SecondPassStruct();

			newStructure.name = FQN.makeFQN(document, structure.name);
			
			foreach (member; structure.variables)
			{
				newStructure.members ~= new NamedType(makeType(FQN.makeFQN(member.type)), member.name);
			}

			addStructure(newStructure);
		}
	}

	void addStructure(SecondPassStruct structure)
	{
		//_structs ~= 
	}

private:
	const FirstPassLibrary _library;
	SecondPassStruct[FQN] _structs;
}*/