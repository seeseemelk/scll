module validator.statements;

import validator.validator2;
import validator.expressions;
import validator.fqn;
import validator.types;

interface StatementVisitor
{
	void visitCallStatement(const LibraryCallStatement statement);
	void visitDeclaringAssignmentStatement(const LibraryDeclaringAssignmentStatement statement);
	void visitAssignmentStatement(const LibraryAssignmentStatement statement);
}

interface LibraryStatement
{
	void visit(StatementVisitor visitor) const;
}

class LibraryCallStatement : LibraryStatement
{
	LibraryMethodDefinition targetMethod;
	LibraryExpression[] expressions;

	void visit(StatementVisitor visitor) const
	{
		visitor.visitCallStatement(this);
	}
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
	FQN variableName;
	LibraryExpression expression;

	void visit(StatementVisitor visitor) const
	{
		visitor.visitAssignmentStatement(this);
	}
}