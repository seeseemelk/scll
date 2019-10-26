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

/*/// A type with a name.
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
}*/

/// Describes a type in SCLL.
interface Type
{
	/// Returns a FQN of the type.
	const(FQN) type() const;

	/// True if the Type is a primitive type, false if it isn't
	bool isPrimitive() const;

	/// True if the type can be instantiated with the given types, false if it can't be.
	bool isInstantiableWith(const Type[] types) const;
}

class PrimitiveType : Type
{
	this(string identifier)
	{
		_fqn = makeFQN(identifier);
	}

	const(FQN) type() const
	{
		return _fqn;
	}

	bool isPrimitive() const
	{
		return true;
	}

	bool isInstantiableWith(const Type[] types) const
	{
		if (types.length != 1)
			return false;
		
		const Type type = types[0];
		if (!type.isPrimitive())
			return false;
		
		return type.type().toString() == _fqn.toString();
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

	const(FQN) type() const
	{
		return _fqn;
	}

	bool isPrimitive() const
	{
		return false;
	}

	bool isInstantiableWith(const Type[] types) const
	{
		assert(0);
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