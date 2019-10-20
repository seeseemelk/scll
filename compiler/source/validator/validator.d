module validator.validator;

import validator.fqn;
import validator.types;
import parser;

private class LibraryMethod
{
    FQN name;
    Type returnType;
    NamedType[] parameters;
}

private class LibraryStruct
{
	FQN name;
	NamedType[] members;
}

private class Context
{
	Type[string] variables;
}

class Library
{
	void addDocument(const ref Document document)
    {
		foreach (interfaceDefinition; document.interfaces)
		{
			foreach (method; interfaceDefinition.methods)
			{
				LibraryMethod libraryMethod = new LibraryMethod();
				libraryMethod.name = makeFQN(interfaceDefinition.name, method.name);
				addMethod(libraryMethod);
			}
		}

        foreach (method; document.methods)
        {
			LibraryMethod libraryMethod = new LibraryMethod();
			libraryMethod.name = makeFQN(document, method.definition.name);
			addMethod(libraryMethod);
        }

		foreach (structure; document.structs)
		{
			LibraryStruct libraryStruct = new LibraryStruct();
			libraryStruct.name = makeFQN(document, structure.name);
			
			foreach (member; structure.variables)
			{
				libraryStruct.members ~= new NamedType(makeFQN(member.type), member.name);
			}
			addStructure(libraryStruct);
		}
    }

	void validateDocument(const ref Document document)
	{
		foreach (method; document.methods)
		{
			LibraryMethod libraryMethod = findMethod(document, method);
			Context context = new Context();
			foreach (statement; method.statements)
			{
				final switch (statement.type)
				{
					case Statement.StatementType.call:
						validateCallStatement(context, document, statement.callStatement);
						break;
					case Statement.StatementType.declaringAssignment:
						validateDeclaringAssignmentStatement(context, document, statement.declaringAssignmentStatement);
						break;
				}
			}
		}
	}

	void validateCallStatement(Context context, const ref Document document, const ref CallStatement statement)
	{
		FQN target = makeFQNContextual(context, makeLocalFQN(document, statement.targetFunction));
		target.add(statement.targetFunction.path[$ - 1]);
		findMethod(target);
	}

	void validateDeclaringAssignmentStatement(Context context,
			const ref Document document, const ref DeclaringAssignmentStatement statement)
	{
		Type type = makeType(makeFQN(statement.type));
		if (!type.isPrimitive())
		{
			findStruct(document, statement.type);
		}
		context.variables[statement.name] = type;
		//new NamedType(type, statement.name);

		Type expressionType = typeOfExpression(context, document, statement.expression);
		if (expressionType != type)
			throw new Exception("Bad type during assignment: expected " ~ type.type.toString() ~ " but got a " ~ type.type.toString());
	}

	void addMethod(LibraryMethod method)
	{
		if (method.name in _methods)
			throw new Exception("Method " ~ method.name.toString() ~ " is redefined");
		import std.stdio : writefln;

		writefln!"Added method %s()"(method.name.toString());
		_methods[method.name] = method;
	}

	void addStructure(LibraryStruct structure)
	{
		if (structure.name in _structs)
			throw new Exception("Struct " ~ structure.name.toString() ~ " is redefined");
		import std.stdio : writefln;

		writefln!"Added structure %s()"(structure.name.toString());
		_structs[structure.name] = structure;
	}

	Type typeOfExpression(Context context, const ref Document document, const ref Expression expression)
	{
		final switch (expression.type)
		{
			case Expression.ExpressionType.identifier:
				return typeOfIdentifier(context, document, expression.identifier);
			case Expression.ExpressionType.stringLiteral:
				return new PrimitiveType("string");
			case Expression.ExpressionType.constructionExpression:
				return typeOfConstruction(context, document, expression.constructionExpression);
		}
	}

	Type typeOfIdentifier(Context context, const ref Document document, string identifier)
	{
		if (identifier in context.variables)
			return context.variables[identifier];
		else
			return new UserType(findStruct(makeFQN(document, identifier)).name);
	}

	Type typeOfConstruction(Context context, const ref Document document, const ref ConstructionExpression expression)
	{
		return makeType(makeFQN(expression.type));
	}

	LibraryMethod findMethod(const ref Document document, const ref PathIdentifier path)
	{
		return findMethod(makeLocalFQN(document, path));
	}

	LibraryMethod findMethod(const ref Document document, const ref Method method)
	{
		return findMethod(makeFQN(document, method.definition.name));
	}

	LibraryMethod findMethod(FQN fqn)
	{
		if (fqn !in _methods)
			throw new Exception("Method " ~ fqn.toString() ~ " not found");
		return _methods[fqn];
	}

	LibraryStruct findStruct(const ref Document document, const ref PathIdentifier path)
	{
		return findStruct(makeLocalFQN(document, path));
	}

	LibraryStruct findStruct(FQN fqn)
	{
		if (fqn !in _structs)
			throw new Exception("Struct " ~ fqn.toString() ~ " not found");
		return _structs[fqn];
	}

	FQN makeFQNContextual(Context context, FQN fqn)
	{
		string type = fqn.parts[0];
		if (type in context.variables)
			return context.variables[type].type();
		else
			return fqn;
	}

	/*Type findType(const ref Document document, const ref PathIdentifier path)
	{
		return findType(FQN.makeLocalFQN(document, path));
	}*/

private:
	const Document[] _documents;
    LibraryMethod[FQN] _methods;
	LibraryStruct[FQN] _structs;
}

/// A first pass library will record structs and method names.
/// It will ignore struct members, and method return types and parameters.
/*private class FirstPassLibrary
{
	void addDocuments(const Document[] documents)
	{
		foreach (document; documents)
		{
			addDocument(document);
		}
	}

	void addDocument(const ref Document document)
	{
		foreach (structure; document.structs)
		{
			addStruct(FQN.makeFQN(document, structure.name));
		}

		foreach (intrf; document.interfaces)
		{
			foreach (method; intrf.methods)
			{
				addMethod(FQN.makeFQN(intrf.name, method.name));
			}
		}

		foreach (method; document.methods)
		{
			addMethod(FQN.makeFQN(document, method.definition.name));
		}
	}

	void addMethod(FQN fqn)
	{
		if (fqn in _methods)
			throw new Exception("Method " ~ fqn.toString() ~ " is already defined");
		_methods[fqn] = fqn;
	}

	void addStruct(FQN fqn)
	{
		if (fqn in _structs)
			throw new Exception("Struct " ~ fqn.toString() ~ " is already defined");
		_structs[fqn] = fqn;
	}

	bool hasMethod(FQN fqn)
	{
		return fqn in _methods;
	}

	bool hasStruct(FQN fqn)
	{
		return fqn in _structs;
	}

private:
	FQN[FQN] _methods;
	FQN[FQN] _structs;
}*/