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

struct InterfaceDefinition
{
    PathIdentifier name;
    MethodDefinition[] methods;
}

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

struct Statement
{
    enum StatementType
    {
        call
    }

    StatementType type;
    union
    {
        CallStatement callStatement;
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

struct Expression
{
    enum ExpressionType
    {
        identifier,
        stringLiteral
    }

    ExpressionType type;
    union
    {
        string identifier;
        string stringLiteral;
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

/// Contains a document.
struct Document
{
    PathIdentifier moduleName;
    InterfaceDefinition[] interfaces;
    Method[] methods;

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
}
