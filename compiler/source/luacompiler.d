module luacompiler;

import validator.validator2;
import parser;
import validator.types;
import std.array;
import std.format;
import std.algorithm;

private class Context
{
    string[string] thisVariables;
}

class Compiler
{
    this(const LibraryDocument document)
    {
        addLine("-- Compiled with version 0.0.1");
        addLine("-- Module: " ~ document.name.toString());

        generateModulePreamble(document);

        foreach (structure; document.structs)
        {
            generateStructure(structure);
        }

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

    void generateModulePreamble(const LibraryDocument document)
    {
        addLine("local " ~ document.name.toString() ~ " = {}");
        addLine();
    }

    void generateModulePostamble(const LibraryDocument document)
    {
        addLine();
        addLine("return " ~ document.name.toString());
    }

    void generateStructure(const LibraryStruct structure)
    {
        addLine("--[[");
        addLine!"Struct: %s"(structure.type.toString());
        indent();
        foreach (member; structure.members)
        {
            addLine!"%s %s"(member.type.type.toString(), member.name);
        }
        undent();
        addLine("--]]");

        foreach (constructor; structure.constructors)
        {
            generateStructConstructor(structure, constructor);
        }
    }

    void generateStructConstructor(const LibraryStruct structure, const LibraryConstructor constructor)
    {
        string funcName = mangle(structure.name.toString(), constructor.parameters);

        addLine!"%s = function(%s)"(funcName, constructor.parameters.map!(type => type.name).array().join(", "));
        indent();

        addLine!"local this = {}";
        foreach (member; structure.members)
        {
            addLine!"this.%s = %s"(member.name, getDefaultInstantiator(member.type));
        }

        foreach (statement; constructor.constructor.statements)
        {
            Context context = new Context();
            foreach (member; structure.members)
            {
                context.thisVariables[member.name] = member.name;
            }

            generateStatement(context, statement);
        }

        addLine!"return this";

        undent();
        addLine!"end"();
            addLine();
    }

    string mangle(string name, const Type[] types)
    {
        if (types.length > 0)
            return name ~ "_" ~ mangle(types);
        else
            return name;
    }

    string mangle(string name, const NamedType[] types)
    {
        return mangle(name, types.map!(type => type.type).array());
    }

    string mangle(const Type[] types)
    {
        return types.map!(type => type.type().parts.join("_")).array().join("__");
    }

    string mangle(const NamedType[] types)
    {
        return mangle(types.map!(type => type.type).array());
    }

    string getDefaultInstantiator(const Type type)
    {
        if (type.isPrimitive)
        {
            switch (type.type().parts[$-1])
            {
                case "string":
                    return `""`;
                case "var":
                    return "0";
                default:
                    throw new Exception("Unexpected primitive type: " ~ type.type().toString());
            }
        }
        
        if (type.isInstantiableWith([]))
        {
            throw new Exception("Advanced instantiation is not yet supported");
        }
        throw new Exception("Type is not instantiable without parameters");
    }

    void generateMethod(const ref LibraryMethod method)
    {
        string name = mangle(method.name.toString(), method.parameters);
        addLine!"%s = function()"(name);
        indent();
        Context context = new Context();
        foreach (statement; method.method.statements)
        {
            generateStatement(context, statement);
        }
        undent();
        addLine!"end";

        if (method.name.parts[$-1] == "main")
        {
            addLine!"%s({...})"(name);
        }
    }

    void generateStatement(Context context, const ref Statement statement)
    {
        final switch (statement.type)
        {
            case Statement.StatementType.call:
                generateCallStatement(context, statement.callStatement);
                break;
			case Statement.StatementType.declaringAssignment:
				generateDeclaringAssignmentStatement(context, statement.declaringAssignmentStatement);
				break;
            case Statement.StatementType.assignment:
                generateAssignmentStatement(context, statement.assignmentStatement);
                break;
        }
    }

    void generateCallStatement(Context context, const ref CallStatement statement)
    {
        string[] arguments;

        foreach (expression; statement.arguments)
        {
            arguments ~= visitExpression(context, expression);
        }

        addLine!"%s(%s)"(
            statement.targetFunction.toString(),
            arguments.join(", ")
        );
    }

	void generateDeclaringAssignmentStatement(Context context, const ref DeclaringAssignmentStatement statement)
	{
		addLine!"local %s = %s"(
			statement.name,
			visitExpression(context, statement.expression)
		);
	}

    void generateAssignmentStatement(Context context, const ref AssignmentStatement statement)
    {
        string name = statement.name;
        if (context.thisVariables[name])
        {
            name = "this." ~ name;
        }

        addLine!"%s = %s"(
            name,
            visitExpression(context, statement.expression)
        );
    }

    string visitExpression(Context context, const ref Expression expression)
    {
        final switch (expression.type)
        {
            case Expression.ExpressionType.identifier:
                return expression.identifier;
            case Expression.ExpressionType.stringLiteral:
                return asStringLiteral(expression.stringLiteral);
            case Expression.ExpressionType.numberLiteral:
                return expression.numberLiteral;
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
		return format!"%s.new()"(expression.type.toString());
	}
}

string compileToLua(const LibraryDocument document)
{
    return new Compiler(document).asLua();
}