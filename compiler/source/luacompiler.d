module luacompiler;

import validator.validator2;
import validator.types;
import validator.statements;
import validator.expressions;
import parser;
import std.array;
import std.format;
import std.algorithm;

private class Context
{
    string[string] thisVariables;
}

class Compiler : StatementVisitor
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

	void visitDeclaringAssignmentStatement(const LibraryDeclaringAssignmentStatement statement)
	{
		string name = statement.variableName;
		string expression = visitExpression(statement.expression);
		addLine!"local %s = %s"(name, expression);
	}

	void visitAssignmentStatement(const LibraryAssignmentStatement statement)
	{
		string name = statement.variableName.toString();
		string expression = visitExpression(statement.expression);
		addLine!"%s = %s"(name, expression);
	}

	void visitCallStatement(const LibraryCallStatement statement)
	{
		string name = statement.targetMethod.fqn().toString();
		string[] expressions = statement.expressions.map!(exp => visitExpression(exp)).array();
		addLine!"%s(%s)"(name, expressions.join(", "));
	}

private:
    string _buffer;
    string _indentation = "";
	Context _context;

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
        addLine!"Struct: %s"(structure.fqn().toString());
        indent();
        foreach (member; structure.members)
        {
            addLine!"%s %s"(member.type.fqn().toString(), member.name);
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
        string funcName = mangle(structure.fqn().toString(), constructor.parameters);

        addLine!"%s = function(%s)"(funcName, constructor.parameters.map!(type => type.name).array().join(", "));
        indent();

        addLine!"local this = {}";
        foreach (member; structure.members)
        {
            addLine!"this.%s = %s"(member.name, getDefaultInstantiator(member.type));
        }

        _context = new Context();
        foreach (statement; constructor.statements)
        {
            foreach (member; structure.members)
            {
                _context.thisVariables[member.name] = member.name;
            }

			statement.visit(this);
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
        return types.map!(type => type.fqn().parts.join("_")).array().join("__");
    }

    string mangle(const NamedType[] types)
    {
        return mangle(types.map!(type => type.type).array());
    }

    string getDefaultInstantiator(const Type type)
    {
        if (type.isPrimitive)
        {
            switch (type.fqn().parts[$-1])
            {
                case "string":
                    return `""`;
                case "var":
                    return "0";
                default:
                    throw new Exception("Unexpected primitive type: " ~ type.fqn().toString());
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
        _context = new Context();
        foreach (statement; method.statements)
        {
			statement.visit(this);
        }
        undent();
        addLine!"end";

        if (method.name.parts[$-1] == "main")
        {
            addLine!"%s({...})"(name);
        }
    }

	string visitExpression(const LibraryExpression expression)
	{
		LuaExpressionBuilder builder = new LuaExpressionBuilder(_context);
		expression.visit(builder);
		return builder.buffer;
	}
}

private class LuaExpressionBuilder : ExpressionVisitor
{
	Context context;
	string buffer;

	this(Context context)
	{
		this.context = context;
	}
	
	void visitConstructionExpression(const LibraryConstructionExpression expression)
	{
		buffer = format!"%s.new()"(expression.constructorType.fqn().toString());
	}

	void visitNumberLiteralExpression(const LibraryNumberLiteralExpression expression)
	{
		buffer = expression.number;
	}

	void visitStringExpression(const LibraryStringExpression expression)
	{
		buffer = format!`"%s"`(expression.value);
	}

	void visitAddSubExpression(const LibraryAddSubExpression expression)
	{
		
	}

	void visitMulDivModExpression(const LibraryMulDivModExpression expression)
	{
		
	}
}

string compileToLua(const LibraryDocument document)
{
    return new Compiler(document).asLua();
}