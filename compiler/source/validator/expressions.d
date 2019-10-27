module validator.expressions;

import validator.types;

/*enum ExpressionType
{
	constructionExpression,
	numberLiteralExpression
}*/

interface LibraryExpression
{
	Type resultType();
}

class LibraryConstructionExpression : LibraryExpression
{
	Type constructorType;
	LibraryExpression[] arguments;

	/*ExpressionType expressionType()
	{
		return ExpressionType.constructionExpression;
	}*/

	Type resultType()
	{
		return constructorType;
	}
}

class LibraryNumberLiteralExpression : LibraryExpression
{
	string number;

	/*ExpressionType expressionType()
	{
		return ExpressionType.numberLiteralExpression;
	}*/
 
	Type resultType()
	{
		return new PrimitiveType("var");
	}
}

/*class LibraryExpression
{
	ExpressionType type;

	union
	{
		LibraryConstructionExpression constructionExpression;
	}
}*/