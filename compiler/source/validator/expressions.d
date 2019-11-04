module validator.expressions;

import validator.types;
import parser : AddSubOperator, MulDivModOperator;

interface ExpressionVisitor
{
	void visitCallExpression(const LibraryCallExpression expression);
	void visitConstructionExpression(const LibraryConstructionExpression expression);
	void visitNumberLiteralExpression(const LibraryNumberLiteralExpression expression);
	void visitStringExpression(const LibraryStringExpression expression);
	void visitAddSubExpression(const LibraryAddSubExpression expression);
	void visitMulDivModExpression(const LibraryMulDivModExpression expression);
}

interface LibraryExpression
{
	Type resultType();
	void visit(ExpressionVisitor visitor) const;
}

interface MethodMangler
{
	import validator.validator2 : LibraryMethod;

	string mangleMethod(const LibraryMethod method);
}

interface LibraryMethodDefinition : Type
{
	import validator.validator2 : NamedType;

	Type returnType();
	const(NamedType[]) parameters() const;
	string mangle(MethodMangler mangler) const;
}

class LibraryCallExpression : LibraryExpression
{
	LibraryMethodDefinition targetMethod;
	LibraryExpression[] expressions;

	Type resultType()
	{
		return targetMethod.returnType;
	}

	void visit(ExpressionVisitor visitor) const
	{
		visitor.visitCallExpression(this);
	}
}

class LibraryConstructionExpression : LibraryExpression
{
	Type constructorType;
	LibraryExpression[] arguments;

	Type resultType()
	{
		return constructorType;
	}

	void visit(ExpressionVisitor visitor) const
	{
		visitor.visitConstructionExpression(this);
	}
}

class LibraryNumberLiteralExpression : LibraryExpression
{
	string number;
 
	Type resultType()
	{
		return new PrimitiveType("var");
	}

	void visit(ExpressionVisitor visitor) const
	{
		visitor.visitNumberLiteralExpression(this);
	}
}

class LibraryStringExpression : LibraryExpression
{
	string value;

	Type resultType()
	{
		return new PrimitiveType("string");
	}

	void visit(ExpressionVisitor visitor) const
	{
		visitor.visitStringExpression(this);
	}
}

class LibraryAddSubExpression : LibraryExpression
{
	AddSubOperator[] operators;
	LibraryExpression[] expressions;

	Type resultType()
	{
		if (expressions.length == 1)
			return expressions[0].resultType();
		return new PrimitiveType("var");
	}

	void visit(ExpressionVisitor visitor) const
	{
		visitor.visitAddSubExpression(this);
	}
}

class LibraryMulDivModExpression : LibraryExpression
{
	MulDivModOperator[] operators;
	LibraryExpression[] expressions;

	Type resultType()
	{
		if (expressions.length == 1)
			return expressions[0].resultType();
		return new PrimitiveType("var");
	}

	void visit(ExpressionVisitor visitor) const
	{
		visitor.visitMulDivModExpression(this);
	}
}