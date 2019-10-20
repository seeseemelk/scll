module parser;

import pegged.parser;
import std.array;

/// Asserts that a tree is of an expected type.
private void assertTree(string type)(const ref ParseTree tree)
{
    assert(tree.name == type, "Expected ParseTree of type " ~ type ~ ", but got " ~ tree.name);
}

/// Always throws an assert error with a special message.
private void assertUnexpected(const ref ParseTree tree)
{
    assert(false, "Unexpected child type " ~ tree.name);
}

/// Contains a path identifier.
struct PathIdentifier
{
    string[] path;

    string toString() const
    {
        return path.join(".");
    }

    this(const ref ParseTree tree)
    {
        assertTree!"SCLL.PathIdentifier"(tree);
        foreach (child; tree.children)
        {
            path ~= child.matches[0];
        }
    }
}

/// Defines an interface
struct InterfaceDefinition
{
    PathIdentifier name;
    MethodDefinition[] methods;
}

/// Defines a method
struct MethodDefinition
{
    string name;
    string returnType;
    Parameter[] parameters;

    this(const ref ParseTree tree)
    {
        assertTree!"SCLL.MethodDefinition"(tree);
        returnType = tree.children[0].matches[0];
        name = tree.children[1].matches[0];

        if (tree.children.length == 2)
            return;

        foreach (child; tree.children[2].children)
        {
            parameters ~= Parameter(child);
        }
    }
}

/// Defines a parameter.
struct Parameter
{
    string type;
    string name;

    this(const ref ParseTree tree)
    {
        assertTree!"SCLL.Parameter"(tree);
        type = tree.children[0].matches[0];
        name = tree.children[1].matches[0];
    }
}

/// Contains a method with a it's definition and implementation.
struct Method
{
    MethodDefinition definition;
    Statement[] statements;

    this(const ref ParseTree tree)
    {
        assertTree!"SCLL.MethodDeclaration"(tree);
        definition = MethodDefinition(tree.children[0]);

        if (tree.children.length == 1)
            return;

        foreach (child; tree.children[1..$])
        {
            statements ~= Statement(child);
        }
    }
}

/// Defines a single statement.
struct Statement
{
    enum StatementType
    {
        call,
		declaringAssignment
    }

    StatementType type;
    union
    {
        CallStatement callStatement;
		DeclaringAssignmentStatement declaringAssignmentStatement;
    }

    this(const ref ParseTree tree)
    {
        assertTree!"SCLL.Statement"(tree);
        visitStatement(tree.children[0]);
    }

private:
    void visitStatement(const ref ParseTree tree)
    {
        switch (tree.name)
        {
            case "SCLL.CallStatement":
                type = StatementType.call;
                callStatement = CallStatement(tree);
                break;
			case "SCLL.DeclaringAssignmentStatement":
				type = StatementType.declaringAssignment;
				declaringAssignmentStatement = DeclaringAssignmentStatement(tree);
				break;
            default:
                assertUnexpected(tree);
        }
    }
}

struct CallStatement
{
    PathIdentifier targetFunction;
    Expression[] arguments;

    this(const ref ParseTree tree)
    {
        targetFunction = PathIdentifier(tree.children[0]);
        if (tree.children.length == 1)
            return;
        foreach (child; tree.children[1].children)
        {
            arguments ~= Expression(child);
        }
    }
}

struct DeclaringAssignmentStatement
{
	PathIdentifier type;
	string name;
	Expression expression;

	this(const ref ParseTree tree)
	{
		type = PathIdentifier(tree.children[0]);
		name = tree.children[1].matches[0];
		expression = Expression(tree.children[2]);
	}
}

struct Expression
{
    enum ExpressionType
    {
        identifier,
        stringLiteral,
		constructionExpression
    }

    ExpressionType type;
    union
    {
        string identifier;
        string stringLiteral;
		ConstructionExpression constructionExpression;
    }

    this(const ref ParseTree tree)
    {
        assertTree!"SCLL.Expression"(tree);
        visitChild(tree.children[0]);
    }

private:
    void visitChild(const ref ParseTree tree)
    {
        switch (tree.name)
        {
            case "SCLL.Literal":
                visitLiteral(tree.children[0]);
                break;
			case "SCLL.TerminalExpression":
				visitChild(tree.children[0]);
				break;
			case "SCLL.ConstructionExpression":
				type = ExpressionType.constructionExpression;
				constructionExpression = ConstructionExpression(tree);
				break;
            default:
                assertUnexpected(tree);
        }
    }

    void visitLiteral(const ref ParseTree tree)
    {
        switch (tree.name)
        {
            case "SCLL.Identifier":
                type = ExpressionType.identifier;
                identifier = tree.matches[0];
                break;
            case "SCLL.StringLiteral":
                type = ExpressionType.stringLiteral;
                identifier = tree.matches[0];
                break;
            default:
                assertUnexpected(tree);
        }
    }
}

struct ConstructionExpression
{
	PathIdentifier type;
	Expression[] arguments;

	this(const ref ParseTree tree)
	{
		type = PathIdentifier(tree.children[0]);
		if (tree.children.length > 1)
			throw new Exception("Constructor parameters are not yet supported");
	}
}

struct StructDefinition
{
	string name;
	StructVariable[] variables;
	Method[] methods;
	Constructor[] constructors;

	this(const ref ParseTree tree)
	{
		assertTree!"SCLL.StructDeclaration"(tree);
		name = tree.children[0].matches[0];

		if (tree.children.length == 1)
			return;

		foreach (child; tree.children[1..$])
		{
			switch (child.name)
			{
				case "SCLL.VariableDeclaration":
					variables ~= StructVariable(child);
					break;
				case "SCLL.MethodDeclaration":
					methods ~= Method(child);
					break;
				case "SCLL.ConstructorDeclaration":
					constructors ~= Constructor(child);
					break;
				default:
					assertUnexpected(child);
			}
		}
	}
}

struct StructVariable
{
	PathIdentifier type;
	string name;

	this(const ref ParseTree tree)
	{
		assertTree!"SCLL.VariableDeclaration"(tree);

		type = PathIdentifier(tree.children[0]);
		name = tree.children[1].matches[0];
	}
}

struct Constructor
{	
	this(const ref ParseTree tree)
	{
		assertTree!"SCLL.ConstructorDeclaration"(tree);
	}
}

/// Contains a document.
struct Document
{
    PathIdentifier moduleName;
    InterfaceDefinition[] interfaces;
    Method[] methods;
	StructDefinition[] structs;

    this(const ref ParseTree tree)
    {
        assertTree!"SCLL"(tree);
        visitDocument(tree.children[0]);
    }

private:

    void visitDocument(const ref ParseTree tree)
    {
        assertTree!"SCLL.Document"(tree);

        foreach (child; tree.children)
        {
            switch (child.name)
            {
                case "SCLL.ModuleDeclaration":
                    visitModuleDeclaration(child);
                    break;
                case "SCLL.Definition":
                    visitDefinition(child);
                    break;
                default:
                    assertUnexpected(child);
            }
        }
    }

    void visitModuleDeclaration(const ref ParseTree tree)
    {
        moduleName = PathIdentifier(tree.children[0]);
    }

    void visitDefinition(const ref ParseTree tree)
    {
        assertTree!"SCLL.Definition"(tree);

        foreach (child; tree.children)
        {
            switch (child.name)
            {
                case "SCLL.InterfaceDefinition":
                    visitInterfaceDefinition(child);
                    break;
                case "SCLL.MethodDeclaration":
                    visitMethodDeclaration(child);
                    break;
				case "SCLL.StructDeclaration":
					visitStructDeclaration(child);
					break;
                default:
                    assertUnexpected(child);
            }
        }
    }

    void visitInterfaceDefinition(const ref ParseTree tree)
    {
        assertTree!"SCLL.InterfaceDefinition"(tree);

        InterfaceDefinition definition;
        definition.name = PathIdentifier(tree.children[0]);

        if (tree.children.length > 1)
        {
            foreach (child; tree.children[1..$])
            {
                definition.methods ~= MethodDefinition(child);
            }
        }

        interfaces ~= definition;
    }

    void visitMethodDeclaration(const ref ParseTree tree)
    {
        assertTree!"SCLL.MethodDeclaration"(tree);
        methods ~= Method(tree);
    }

	void visitStructDeclaration(const ref ParseTree tree)
	{
		assertTree!"SCLL.StructDeclaration"(tree);
		structs ~= StructDefinition(tree);
	}
}
