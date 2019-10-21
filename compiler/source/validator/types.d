module validator.types;

import validator.fqn;

bool isPrimitive(string type)
{
	switch (type)
	{
		case "string":
		case "var":
		case "void":
			return true;
		default:
			return false;
	}
}

/// Creates a Type object from an identifier.
Type makeType(FQN fqn)
{
	if (fqn.parts.length == 1)
	{
		string type = fqn.parts[0];
		switch (type)
		{
			case "string":
			case "var":
			case "void":
				return new PrimitiveType(type);
			default:
				return new UserType(fqn);
		}
	}
	else
	{
		return new UserType(fqn);
	}
}

/// A type with a name.
class NamedType
{
	Type type;
	string name;

	this(Type type, string name)
	{
		this.type = type;
		this.name = name;
	}

	this(FQN fqn, string name)
	{
		this(makeType(fqn), name);
	}
}

/// Describes a type in SCLL.
interface Type
{
	/// Returns a FQN of the type.
	FQN type();

	/// True if the Type is a primitive type, false if it isn't
	bool isPrimitive();
}

class PrimitiveType : Type
{
	this(string identifier)
	{
		_fqn = makeFQN(identifier);
	}

	FQN type()
	{
		return _fqn;
	}

	bool isPrimitive()
	{
		return true;
	}

	override bool opEquals(Object b)
	{
		PrimitiveType other = cast(PrimitiveType) b;
		if (other is null)
			return false;
		return _fqn == other._fqn;
	}

private:
	FQN _fqn;
}

class UserType : Type
{
	this(FQN fqn)
	{
		_fqn = fqn;
	}

	FQN type()
	{
		return _fqn;
	}

	bool isPrimitive()
	{
		return false;
	}

	override bool opEquals(Object b)
	{
		UserType other = cast(UserType) b;
		if (other is null)
			return false;
		return _fqn == other._fqn;
	}

private:
	FQN _fqn;
}