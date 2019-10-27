module validator.statements;

import validator.validator2;
import validator.expressions;
import validator.fqn;
import validator.types;

interface LibraryStatement
{

}

class LibraryCallStatement : LibraryStatement
{
	LibraryMethodDefinition targetMethod;
	LibraryExpression[] expressions;
}

class LibraryDeclaringAssignmentStatement : LibraryStatement
{
	string variableName;
	Type variableType;
	LibraryExpression expression;
}

class LibraryAssignmentStatement : LibraryStatement
{
	FQN variableName;
	LibraryExpression expression;
}

/*enum StatementType
{
	callStatement,
	declaringAssignmentStatement,
	assignmentStatement,
}

class LibraryStatement
{
	StatementType type;

	union
	{
		LibraryCallStatement callStatement;
		LibraryDeclaringAssignmentStatement declaringAssignmentStatement;
		LibraryAssignmentStatement assignmentStatement;
	}
}*/