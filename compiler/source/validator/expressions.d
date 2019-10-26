module validator.expressions;

import validator.types;

enum ExpressionType
{
	constructionExpression
}

class LibraryConstructionExpression
{
	Type constructorType;
	LibraryExpression[] arguments;
}

class LibraryExpression
{
	ExpressionType type;

	union
	{
		LibraryConstructionExpression constructionExpression;
	}
}