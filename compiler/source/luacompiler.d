module luacompiler;

import parser;
import std.array;
import std.format;

class Compiler
{
    this(const ref Document document)
    {
        addLine("-- Compiled with version 0.0.1");
        addLine("-- Module: " ~ document.moduleName.toString());

        generateModulePreamble(document);

        foreach (method; document.methods)
        {
            generateMethod(method);
        }

        generateModulePostamble(document);
    }

    string asLua() const
    {
        return _buffer;
    }

private:
    string _buffer;
    string _indentation = "";

    void add(string code)
    {
        _buffer ~= code;
    }

    void add(string fmt, T...)(T t)
    {
        _buffer = format!fmt(t);
    }

    void addLine(string line)
    {
        _buffer ~= _indentation;
        _buffer ~= line;
        _buffer ~= '\n';
    }

    void addLine(string fmt, T...)(T t)
    {
        _buffer ~= _indentation;
        _buffer ~= format!fmt(t);
        _buffer ~= '\n';
    }

    void addLine()
    {
        _buffer ~= '\n';
    }

    void indent()
    {
        _indentation ~= "    ";
    }

    void undent()
    {
        _indentation = _indentation[0 .. $-4];
    }

    void generateModulePreamble(const ref Document document)
    {
        addLine("local _module = {}");
        addLine();
    }

    void generateModulePostamble(const ref Document document)
    {
        addLine();
        addLine("return _module");
    }

    void generateMethod(const ref Method method)
    {
        addLine!"function %s()"(method.definition.name);
        indent();
        foreach (statement; method.statements)
        {
            generateStatement(statement);
        }
        undent();
        addLine!"end";
    }

    void generateStatement(const ref Statement statement)
    {
        final switch (statement.type)
        {
            case Statement.StatementType.call:
                generateCallStatement(statement.callStatement);
                break;
			case Statement.StatementType.declaringAssignment:
				generateDeclaringAssignmentStatement(statement.declaringAssignmentStatement);
				break;
        }
    }

    void generateCallStatement(const ref CallStatement statement)
    {
        string[] arguments;

        foreach (expression; statement.arguments)
        {
            arguments ~= visitExpression(expression);
        }

        addLine!"%s(%s)"(
            statement.targetFunction.toString(),
            arguments.join(", ")
        );
    }

	void generateDeclaringAssignmentStatement(const ref DeclaringAssignmentStatement statement)
	{
		addLine!"local %s = %s"(
			statement.name,
			visitExpression(statement.expression)
		);
	}

    string visitExpression(const ref Expression expression)
    {
        final switch (expression.type)
        {
            case Expression.ExpressionType.identifier:
                return expression.identifier;
            case Expression.ExpressionType.stringLiteral:
                return asStringLiteral(expression.stringLiteral);
			case Expression.ExpressionType.constructionExpression:
				return visitConstructionExpression(expression.constructionExpression);
        }
    }

    string asStringLiteral(string text)
    {
        return '"' ~ text ~ '"';
    }

	string visitConstructionExpression(const ref ConstructionExpression expression)
	{
		return format!"%s.new()"(expression.type);
	}
}

string compileToLua(const ref Document document)
{
    return new Compiler(document).asLua();
}
