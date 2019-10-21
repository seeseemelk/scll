module validator.validator2;

import parser;
import validator.fqn;
import validator.types;

class NamedType
{
	string name;
	Type type;

	this() {}

	this(string name, Type type)
	{
		this.name = name;
		this.type = type;
	}
}

class LibraryMethod
{
	const Method method;
	FQN name;
	Type returnType;
	NamedType[] parameters;

	this(const Method method)
	{
		this.method = method;
	}
}

class LibraryStruct : Type
{
	const StructDefinition definition;
	FQN name;
	NamedType[] members;
	LibraryMethod[] methods;

	this(const StructDefinition definition)
	{
		this.definition = definition;
	}

	FQN childFQN(string child)
	{
		return makeFQN(name, child);
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
	LibraryMethod[] methods;

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

class Context
{
	LibraryDocument document;
	NamedType[] locals;

	this(LibraryDocument document)
	{
		this.document = document;
	}
}

class Library
{
	LibraryDocument addDocument(const ref Document document)
	{
		LibraryDocument libraryDocument = new LibraryDocument(document);
		libraryDocument.name = makeFQN(document.moduleName);

		// Find every struct
		foreach (structure; document.structs)
		{
			LibraryStruct libraryStruct = new LibraryStruct(structure);
			libraryStruct.name = libraryDocument.childFQN(structure.name);
			libraryDocument.structs ~= libraryStruct;

			// Find every struct method
			foreach (method; structure.methods)
			{
				LibraryMethod libraryMethod = new LibraryMethod(method);
				libraryMethod.name = libraryStruct.childFQN(method.definition.name);
				libraryStruct.methods ~= libraryMethod;
			}
		}

		// Find every method
		foreach (method; document.methods)
		{
			LibraryMethod libraryMethod = new LibraryMethod(method);
			libraryMethod.name = libraryDocument.childFQN(method.definition.name);
			libraryDocument.methods ~= libraryMethod;
		}

		_documents ~= libraryDocument;
		return libraryDocument;
	}

	void firstPass()
	{
		foreach (document; _documents)
		{
			// Pass every struct
			foreach (structure; document.structs)
			{
				// Pass every struct member
				foreach (member; structure.definition.variables)
				{
					NamedType structMember = new NamedType();
					structMember.name = member.name;
					structMember.type = findType(document, member.type);
					structure.members ~= structMember;
				}

				// Pass every struct method
				foreach (method; structure.methods)
				{
					Context context = new Context(document);
					foreach (member; structure.members)
					{
						context.locals ~= member;
					}

					method.returnType = findType(document, method.method.definition.returnType);
					foreach (parameter; method.method.definition.parameters)
					{
						method.parameters ~= new NamedType(parameter.name, findType(document, parameter.type));
					}
					validateMethod(context, method);
				}
			}

			// Pass every method
			foreach (method; document.methods)
			{
				Context context = new Context(document);
				method.returnType = findType(document, method.method.definition.returnType);
				foreach (parameter; method.method.definition.parameters)
				{
					method.parameters ~= new NamedType(parameter.name, findType(document, parameter.type));
				}
				validateMethod(context, method);
			}
		}
	}

	void validateMethod(Context context, LibraryMethod method)
	{
		foreach (statement; method.method.statements)
		{
			final switch (statement.type)
			{
				case Statement.StatementType.declaringAssignment:
					validateDeclaringAssignmentStatement(context, statement.declaringAssignmentStatement);
					break;
				case Statement.StatementType.call:
					validateCallStatement(context, statement.callStatement);
					break;
			}
		}
	}

	void validateDeclaringAssignmentStatement(Context context, const DeclaringAssignmentStatement statement)
	{
		Type targetType = findType(context.document, statement.type);
		Type expressionType = typeOf(context, statement.expression);
		if (targetType != expressionType)
			throw new Exception("Expected a " ~ targetType.type().toString() ~ ", but got a " ~ expressionType.type().toString());
	}

	void validateCallStatement(Context context, const CallStatement statement)
	{
		assert(0);
	}

	Type typeOf(Context context, const Expression expression)
	{
		final switch (expression.type)
		{
			case Expression.ExpressionType.constructionExpression:
				return typeOf(context, expression.constructionExpression);
			case Expression.ExpressionType.stringLiteral:
				return new PrimitiveType("string");
			case Expression.ExpressionType.identifier:
				assert(0);
		}
	}

	Type typeOf(Context context, const ConstructionExpression expression)
	{
		// TODO Validate arguments
		return findType(context, expression.type);
	}

	Type findType(Context context, const PathIdentifier identifier)
	{
		return findType(context.document, identifier);
	}

	Type findType(LibraryDocument document, string name)
	{
		if (isPrimitive(name))
			return new PrimitiveType(name);
		return findType(makeFQN(document.document, name));
	}

	Type findType(LibraryDocument document, const PathIdentifier identifier)
	{
		if (identifier.path.length > 1)
			return findType(makeFQN(identifier));

		string value = identifier.path[0];
		if (isPrimitive(value))
			return new PrimitiveType(value);
		
		return findType(makeFQN(document.document, identifier));
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

	LibraryDocument parseDocuments(string[] documents)
	{
		Library library = new Library();
		LibraryDocument libraryDocument;
		foreach (str; documents)
		{
			ParseTree parsetree = lexDocument(str);
			Document document = Document(parsetree);
			libraryDocument = library.addDocument(document);
			library.firstPass();
		}
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
	struct Test {var a;}
	struct OtherTest {Test wow;}
	`);
	assert(document.structs[0].members[0].type.type().toString() == "var");
	assert(document.structs[0].members[0].type.isPrimitive());

	assert(parseDocument(`
	module myModule;
	struct Test {void testMethod() {}}
	`).structs[0].methods[0].name.toString() == "myModule.Test.testMethod", "Struct method was not correctly parsed");

	assert(parseDocument(`
	module myModule;
	struct Bee {}
	struct Test {Bee testMethod() {}}
	`).structs[1].methods[0].returnType.type().toString() == "myModule.Bee", "Struct method return type was not correctly parsed");

	assert(parseDocument(`
	module myModule;
	struct Bee {}
	struct Test {var testMethod() {}}
	`).structs[1].methods[0].returnType.type().toString() == "var", "Struct method return type was not correctly parsed");

	assert(parseDocument(`
	module myModule;
	string hello() {}
	`).methods[0].returnType.type().toString() == "string", "Method return type was not correctly parsed");

	assert(parseDocument(`
	module myModule;
	string hello() {}
	`).methods[0].name.toString() == "myModule.hello", "Method name was not correctly parsed");

	assert(parseDocument(`
	module myModule;
	struct MyStruct {}
	MyStruct hello() {}
	`).methods[0].returnType.type().toString() == "myModule.MyStruct", "Method return type was not correctly parsed");

	assert(parseDocument(`
	module myModule;
	struct MyStruct {}
	void hello() {MyStruct val = new MyStruct();}
	`));
}