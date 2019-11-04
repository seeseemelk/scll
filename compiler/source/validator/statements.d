module validator.statements;

import validator.validator2;
import validator.expressions;
import validator.fqn;
import validator.types;

interface StatementVisitor
{
	void visitDeclaringAssignmentStatement(const LibraryDeclaringAssignmentStatement statement);
	void visitAssignmentStatement(const LibraryAssignmentStatement statement);
}

interface LibraryStatement
{
	void visit(StatementVisitor visitor) const;
}

class LibraryDeclaringAssignmentStatement : LibraryStatement
{
	string variableName;
	Type variableType;
	LibraryExpression expression;

	void visit(StatementVisitor visitor) const
	{
		visitor.visitDeclaringAssignmentStatement(this);
	}
}

class LibraryAssignmentStatement : LibraryStatement
{
	string variableName;
	Type variableType;
	LibraryExpression expression;

	void visit(StatementVisitor visitor) const
	{
		visitor.visitAssignmentStatement(this);
	}
}