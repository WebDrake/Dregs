module dregs.core;

class Rating(UserID = size_t, ObjectID = size_t)
{
	private UserID user_;
	private ObjectID object_;

	this(UserID u, ObjectID o)
	{
		user_ = u;
		object_ = o;
	}

	final pure nothrow UserID user()
	{
		return user_;
	}

	final pure nothrow ObjectID object()
	{
		return object_;
	}
}


class Rating(UserID = size_t, ObjectID = size_t, Reputation = double) : Rating!(UserID, ObjectID)
{
	private Reputation weight_;

	this(UserID u, ObjectID o, Reputation r)
	{
		super(u, o);
		weight_ = r;
	}

	final pure nothrow Reputation weight()
	{
		return weight_;
	}
}
