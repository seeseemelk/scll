module validator.validator2;

import validator.expressions;
import validator.statements;
import parser;
import validator.fqn;
import validator.types;
import std.array;
import std.algorithm;
import std.stdio;

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

interface LibraryMethodDefinition : Type
{
	Type returnType();
	const(NamedType[]) parameters() const;
}

class LibraryInterfaceMethod : Type, LibraryMethodDefinition
{
	const MethodDefinition method;
	FQN name;

	this(const MethodDefinition method)
	{
		this.method = method;
	}

	bool isPrimitive() const
	{
		return false;
	}

	bool isInstantiableWith(const Type[] types) const
	{
		foreach (i, parameter; _parameters)
		{
			if (!parameter.type.isInstantiableWith([types[i]]))
				return false;
		}
		return true;
	}

	const(FQN) fqn() const
	{
		return name;
	}

	Type returnType()
	{
		return _returnType;
	}

	void returnType(Type returnType)
	{
		_returnType = returnType;
	}

	const(NamedType[]) parameters() const
	{
		return _parameters;
	}

	void addParameter(NamedType type)
	{
		_parameters ~= type;
	}

private:
	Type _returnType;
	NamedType[] _parameters;
}

class LibraryMethod : Type, LibraryMethodDefinition
{
	const Method method;
	LibraryStatement[] statements;
	FQN name;

	this(const Method method)
	{
		this.method = method;
	}

	bool isPrimitive() const
	{
		return false;
	}

	bool isInstantiableWith(const Type[] types) const
	{
		foreach (i, parameter; _parameters)
		{
			if (!parameter.type.isInstantiableWith([types[i]]))
				return false;
		}
		return true;
	}

	const(FQN) fqn() const
	{
		return name;
	}

	Type returnType()
	{
		return _returnType;
	}

	void returnType(Type returnType)
	{
		_returnType = returnType;
	}

	const(NamedType[]) parameters() const
	{
		return _parameters;
	}

	void addParameter(NamedType type)
	{
		_parameters ~= type;
	}

private:
	Type _returnType;
	NamedType[] _parameters;
}

class LibraryConstructor
{
	const Constructor constructor;
	NamedType[] parameters;
	LibraryStatement[] statements;

	this(const Constructor constructor)
	{
		this.constructor = constructor;
	}
}

class LibraryStruct : Type
{
	const StructDefinition definition;
	NamedType[] members;
	LibraryMethod[] methods;
	LibraryConstructor[] constructors;
	FQN name;

	this(const StructDefinition definition)
	{
		this.definition = definition;
	}

	FQN childFQN(string child)
	{
		return makeFQN(name, child);
	}

	bool isPrimitive() const
	{
		return false;
	}

	bool isInstantiableWith(const Type[] types) const
	{
		// If we don't have a constructor,
		// let's check for the default constructor.
		if (constructors.length == 0 && types.length == 0)
			return true;

		// Otherwise, check for a real constructor.
		foreach (constructor; constructors)
		{
			if (isInstantiableWith(constructor, types))
				return true;
		}
		return false;
	}

	bool isInstantiableWith(const LibraryConstructor constructor, const Type[] types) const
	{
		if (constructor.parameters.length != types.length)
			return false;
		
		foreach (i, parameter; constructor.parameters)
		{
			if (!parameter.type.isInstantiableWith([types[i]]))
				return false;
		}
		return true;
	}

	const(FQN) fqn() const
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
	LibraryInterface[] interfaces;

	this(const Document document)
	{
		this.document = document;
	}

	FQN childFQN(string child)
	{
		return makeFQN(name, child);
	}

	bool hasType(FQN path)
	{
		foreach (structure; structs)
		{
			if (structure.name == path)
				return true;
		}
		return false;
	}

	Type findType(FQN path)
	{
		writeln("Path: " ~ path.toString());
		foreach (structure; structs)
		{
			if (structure.name == path)
				return structure;
		}

		foreach (intrf; interfaces)
		{
			foreach (method; intrf.methods)
			{
				writeln("Interface: " ~ method.name.toString());
				if (method.name == path)
					return method;
			}
		}
		throw new Exception("Type " ~ path.toString() ~ " not found");
	}

	LibraryMethodDefinition findMethod(FQN methodName)
	{
		foreach (method; methods)
		{
			if (method.name == methodName)
				return method;
		}
		foreach (intrf; interfaces)
		{
			foreach (method; intrf.methods)
			{
				if (method.name == methodName)
					return method;
			}
		}
		throw new Exception("Method " ~ methodName.toString() ~ " not found");
	}
}

class LibraryInterface
{
	const InterfaceDefinition intrf;
	FQN name;
	LibraryInterfaceMethod[] methods;

	this (const InterfaceDefinition intrf)
	{
		this.intrf = intrf;
	}

	FQN childFQN(string child)
	{
		return makeFQN(name, child);
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
	void allPasses()
	{
		firstPass();
		secondPass();
	}

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

			// Find every constructor
			foreach (method; structure.constructors)
			{
				LibraryConstructor libraryConstructor = new LibraryConstructor(method);
				libraryStruct.constructors ~= libraryConstructor;
			}
		}

		// Find every method
		foreach (method; document.methods)
		{
			LibraryMethod libraryMethod = new LibraryMethod(method);
			libraryMethod.name = libraryDocument.childFQN(method.definition.name);
			libraryDocument.methods ~= libraryMethod;
		}

		// Find every interface
		foreach (intrf; document.interfaces)
		{
			LibraryInterface libraryInterface = new LibraryInterface(intrf);
			writeln("Interface: " ~ intrf.name);
			libraryInterface.name = libraryDocument.childFQN(intrf.name);
			libraryDocument.interfaces ~= libraryInterface;

			// Find every interface method.
			foreach (method; intrf.methods)
			{
				LibraryInterfaceMethod libraryMethod = new LibraryInterfaceMethod(method);
				writeln("Interface method name: " ~ method.name);
				libraryMethod.name = libraryInterface.childFQN(method.name);
				writeln("Interface method name: " ~ libraryMethod.name.toString());
				libraryInterface.methods ~= libraryMethod;
			}
		}

		_documents ~= libraryDocument;
		return libraryDocument;
	}

	/// First pass will resolve all return types and method arguments.
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

				// Pass every constructor
				foreach (constructor; structure.constructors)
				{
					foreach (parameter; constructor.constructor.parameters)
					{
						constructor.parameters ~= new NamedType(parameter.name, findType(document, parameter.type));
					}
				}

				// Pass every struct method
				firstPassMethods(document, structure.methods);
			}

			// Pass every interface
			foreach (intrf; document.interfaces)
			{
				// Pass every interface method
				foreach (method; intrf.methods)
				{
					method.returnType = findType(document, method.method.returnType);
					foreach (parameter; method.method.parameters)
					{
						method.addParameter(new NamedType(parameter.name, findType(document, parameter.type)));
					}
				}
			}

			// Pass every method
			firstPassMethods(document, document.methods);
		}
	}

	void firstPassMethods(LibraryDocument document, LibraryMethod[] methods)
	{
		foreach (method; methods)
		{
			firstPassMethod(document, method);
		}
	}

	void firstPassMethod(LibraryDocument document, LibraryMethod method)
	{
		method.returnType = findType(document, method.method.definition.returnType);
		foreach (parameter; method.method.definition.parameters)
		{
			method.addParameter(new NamedType(parameter.name, findType(document, parameter.type)));
		}
	}

	/// Second pass will populate method bodies.
	void secondPass()
	{
		// Pass every document
		foreach (document; _documents)
		{
			// Pass every struct
			foreach (structure; document.structs)
			{
				// Pass every struct constructor
				foreach (method; structure.constructors)
				{
				}

				// Pass every struct method
				foreach (method; structure.methods)
				{
					Context context = new Context(document);
					foreach (member; structure.members)
					{
						context.locals ~= member;
					}
					context.locals ~= new NamedType("this", structure);
					populateMethod(context, method);
				}
			}

			// Pass every method
			foreach (method; document.methods)
			{
				Context context = new Context(document);
				populateMethod(context, method);
			}
		}
	}

	void populateMethod(Context context, LibraryMethod method)
	{
		foreach (statement; method.method.statements)
		{
			LibraryStatement lstatement;
			final switch (statement.type)
			{
				case Statement.StatementType.declaringAssignment:
					lstatement = createDeclaringAssignmentStatement(context, statement.declaringAssignmentStatement);
					break;
				case Statement.StatementType.assignment:
					assert(0);
					//validateAssignmentStatement(context, statement.assignmentStatement);
					//break;
				case Statement.StatementType.call:
					//validateCallStatement(context, statement.callStatement);
					lstatement = createCallStatement(context, statement.callStatement);
					break;
			}
			method.statements ~= lstatement;
		}
	}

	LibraryDeclaringAssignmentStatement createDeclaringAssignmentStatement(Context context, const DeclaringAssignmentStatement statement)
	{
		LibraryDeclaringAssignmentStatement lstatement = new LibraryDeclaringAssignmentStatement();
		Type targetType = findType(context.document, statement.type);

		lstatement.variableName = statement.name;
		lstatement.variableType = targetType;
		lstatement.expression = createExpression(context, statement.expression);

		if (lstatement.expression.resultType() != lstatement.variableType)
			throw new Exception("Expected a " ~ targetType.fqn().toString() ~ ", but got a " ~ lstatement.expression.resultType().fqn().toString());
		
		return lstatement;
	}

	LibraryCallStatement createCallStatement(Context context, const CallStatement statement)
	{
		LibraryCallStatement lstatement = new LibraryCallStatement();

		lstatement.targetMethod = findMethod(context, statement.targetFunction);

		foreach (expression; statement.arguments)
		{
			lstatement.expressions ~= createExpression(context, expression);
		}

		Type[] types = lstatement.expressions.map!(exp => exp.resultType()).array();
		if (!lstatement.targetMethod.isInstantiableWith(types))
		{
			throw new Exception("Method not callable with given arguments");
		}

		return lstatement;
	}

	/*void validateAssignmentStatement(Context context, const AssignmentStatement statement)
	{
		Type targetType = findType(context.document, statement.name);
		Type expressionType = typeOf(context, statement.expression);
		if (targetType != expressionType)
			throw new Exception("Expected a " ~ targetType.type().toString() ~ ", but got a " ~ expressionType.type().toString());
	}

	void validateCallStatement(Context context, const CallStatement statement)
	{
		Type type = findType(context, statement.targetFunction);
		Type[] arguments = typesOf(context, statement.arguments);

		if (!type.isInstantiableWith(arguments))
		{
			throw new Exception(type.type.toString ~ " is not instantiable with types "
					~ arguments.map!(arg => arg.type.toString()).join(", "));
		}
	}*/

	LibraryExpression createExpression(Context context, const Expression expression)
	{
		final switch (expression.type)
		{
			case Expression.ExpressionType.constructionExpression:
				return createConstructionExpression(context, expression.constructionExpression);
			case Expression.ExpressionType.numberLiteral:
				return createNumberExpression(context, expression.numberLiteral);
			case Expression.ExpressionType.stringLiteral:
				return createStringExpression(context, expression.stringLiteral);
			case Expression.ExpressionType.identifier:
				assert(0, "Identifier not implemented");
		}
	}

	LibraryConstructionExpression createConstructionExpression(Context context, const ConstructionExpression expression)
	{
		LibraryConstructionExpression lexpression = new LibraryConstructionExpression();
		lexpression.constructorType = findType(context, expression.type);
		foreach (argument; expression.arguments)
		{
			lexpression.arguments ~= createExpression(context, argument);
		}
		Type[] parameters = lexpression.arguments.map!(exp => exp.resultType()).array();
		if (!lexpression.constructorType.isInstantiableWith(parameters))
		{
			string name = parameters.map!(type => type.fqn().toString()).join(", ");
			throw new Exception("Struct " ~ lexpression.resultType.fqn.toString() ~ " is not instantiable with parameters " ~ name);
		}
		return lexpression;
	}

	LibraryNumberLiteralExpression createNumberExpression(Context context, const string value)
	{
		LibraryNumberLiteralExpression lexpression = new LibraryNumberLiteralExpression();
		lexpression.number = value;
		return lexpression;
	}

	LibraryStringExpression createStringExpression(Context context, const string value)
	{
		LibraryStringExpression lexpression = new LibraryStringExpression();
		lexpression.value = value;
		return lexpression;
	}

	/*Type typeOf(Context context, const Expression expression)
	{
		final switch (expression.type)
		{
			case Expression.ExpressionType.constructionExpression:
				return typeOf(context, expression.constructionExpression);
			case Expression.ExpressionType.stringLiteral:
				return new PrimitiveType("string");
			case Expression.ExpressionType.numberLiteral:
				return new PrimitiveType("var");
			case Expression.ExpressionType.identifier:
				assert(0);
		}
	}

	Type typeOf(Context context, const ConstructionExpression expression)
	{
		Type returnType = findType(context, expression.type);

		Type[] arguments = typesOf(context, expression.arguments);

		if (!returnType.isInstantiableWith(arguments))
		{
			throw new Exception(returnType.type.toString ~ " is not instantiable with types "
					~ arguments.map!(arg => arg.type.toString()).join(", "));
		}
		
		return returnType;
	}

	Type[] typesOf(Context context, const Expression[] expressions)
	{
		Type[] arguments;

		foreach (argument; expressions)
		{
			arguments ~= typeOf(context, argument);
		}

		return arguments;
	}*/

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
		if (identifier.path.length == 1)
		{
			string value = identifier.path[0];
			if (isPrimitive(value))
				return new PrimitiveType(value);
		}
		
		return findType(makeFQN(document.document, identifier));
	}

	Type findType(FQN fqn)
	{
		string moduleName = fqn.parts[0];
		return findDocument(moduleName).findType(fqn);
	}

	LibraryMethodDefinition findMethod(Context context, const PathIdentifier identifier)
	{
		return findMethod(context.document, identifier);
	}

	LibraryMethodDefinition findMethod(LibraryDocument document, const PathIdentifier identifier)
	{
		return findMethod(makeFQN(document.document, identifier));
	}

	LibraryMethodDefinition findMethod(FQN fqn)
	{
		return findDocument(fqn.parts[0]).findMethod(fqn);
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
		library.allPasses();
		return libraryDocument;
	}

	void assertParses(string str)
	{
		Library library = new Library();
		ParseTree parsetree = lexDocument(str);
		Document document = Document(parsetree);
		LibraryDocument libraryDocument = library.addDocument(document);
		library.allPasses();
	}

	void assertNotParses(string str)
	{
		try
		{
			Library library = new Library();
			ParseTree parsetree = lexDocument(str);
			Document document = Document(parsetree);
			LibraryDocument libraryDocument = library.addDocument(document);
			library.allPasses();
			assert(0, "Document validated, but shouldn't have.");
		}
		catch (Exception e) {}
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
			library.allPasses();
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
	assert(document.structs[0].members[0].type.fqn().toString() == "var");
	assert(document.structs[0].members[0].type.isPrimitive());

	assert(parseDocument(`
	module myModule;
	struct Test {void testMethod() {}}
	`).structs[0].methods[0].name.toString() == "myModule.Test.testMethod", "Struct method was not correctly parsed");

	assert(parseDocument(`
	module myModule;
	struct Bee {}
	struct Test {Bee testMethod() {}}
	`).structs[1].methods[0].returnType.fqn().toString() == "myModule.Bee", "Struct method return type was not correctly parsed");

	assert(parseDocument(`
	module myModule;
	struct Bee {}
	struct Test {var testMethod() {}}
	`).structs[1].methods[0].returnType.fqn().toString() == "var", "Struct method return type was not correctly parsed");

	assert(parseDocument(`
	module myModule;
	string hello() {}
	`).methods[0].returnType.fqn().toString() == "string", "Method return type was not correctly parsed");

	assert(parseDocument(`
	module myModule;
	string hello() {}
	`).methods[0].name.toString() == "myModule.hello", "Method name was not correctly parsed");

	assert(parseDocument(`
	module myModule;
	struct MyStruct {}
	MyStruct hello() {}
	`).methods[0].returnType.fqn().toString() == "myModule.MyStruct", "Method return type was not correctly parsed");

	assertParses(`
	module myModule;
	struct MyStruct {}
	void hello() {MyStruct val = new MyStruct();}
	`);

	assertParses(`
	module myModule;
	struct MyStruct
	{
		new(var param) {}
	}
	`);

	assertNotParses(`
	module myModule;
	struct MyStruct
	{
		new(OtherStruct param) {}
	}
	`);

	assertParses(`
	module myModule;
	struct OtherStruct {}
	struct MyStruct
	{
		new(OtherStruct param) {}
	}
	`);

	assertParses(`
	module myModule;
	struct MyStruct
	{
		new(var hello) {}
	}
	void main()
	{
		MyStruct variable = new MyStruct(5);
	}
	`);

	assertNotParses(`
	module myModule;
	struct MyStruct
	{
		new() {}
	}
	void main()
	{
		MyStruct variable = new MyStruct(5);
	}
	`);

	assertNotParses(`
	module myModule;
	void main()
	{
		io.write("test");
	}
	`);

	assertParses(`
	module myModule;
	interface io
	{
		void write(string name);
	}
	void main()
	{
		io.write("test");
	}
	`);

	assertNotParses(`
	module myModule;
	interface io
	{
		void write(string name);
	}
	void main()
	{
		io.write(5);
	}
	`);
}