module validator.fqn;

import parser;
import std.array;

struct FQN
{
    string[] parts;

    this(const ref PathIdentifier path)
    {
		add(path);
    }

	this(string name)
	{
		parts ~= name;
	}

	void add(const ref PathIdentifier path)
	{
		foreach (part; path.path)
        {
            parts ~= part;
        }
	}

	void add(string part)
	{
		parts ~= part;
	}

	string toString()
	{
		return parts.join(".");
	}
}

FQN makeFQN(const ref Document document, const ref PathIdentifier path)
{
	FQN fqn = FQN(document.moduleName);
	fqn.add(path);
	return fqn;
}

FQN makeFQN(const ref PathIdentifier path1, const ref PathIdentifier path2)
{
	FQN fqn = FQN(path1);
	fqn.add(path2);
	return fqn;
}

FQN makeFQN(const ref PathIdentifier path1, string name)
{
	FQN fqn = FQN(path1);
	fqn.parts ~= name;
	return fqn;
}

FQN makeFQN(const ref Document document, string name)
{
	FQN fqn = FQN(document.moduleName);
	fqn.parts ~= name;
	return fqn;
}

FQN makeFQN(string name)
{
	return FQN(name);
}

FQN makeFQN(const ref PathIdentifier path)
{
	return FQN(path);
}

FQN makeLocalFQN(const ref Document document, const ref PathIdentifier path)
{
	if (path.path.length == 1)
		return makeFQN(document, path);
	else
		return makeFQN(path);
}

FQN makeFQN(const ref FQN baseFQN, string name)
{
	FQN fqn;
	foreach (part; baseFQN.parts)
	{
		fqn.parts ~= part;
	}
	fqn.parts ~= name;
	return fqn;
}