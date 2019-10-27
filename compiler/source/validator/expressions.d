module validator.expressions;

import validator.types;

interface ExpressionVisitor
{
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