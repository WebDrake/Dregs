module dregs.core;

struct Rating(UserID = size_t, ObjectID = size_t, Reputation = double)
{
	private UserID user_;
	private ObjectID object_;
	private Reputation weight_;

	this(UserID u, ObjectID o, Reputation r)
	{
		user_ = u;
		object_ = o;
		weight_ = r;
	}

	final pure nothrow UserID user()
	{
		return user_;
	}

	final pure nothrow ObjectID object()
	{
		return object_;
	}
	
	final pure nothrow Reputation weight()
	{
		return weight_;
	}
}
