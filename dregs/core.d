module dregs.core;

struct Rating(UserID = size_t, ObjectID = size_t, Reputation = double)
{
	UserID user;
	ObjectID object;
	Reputation weight;

	this(UserID u, ObjectID o, Reputation r)
	{
		user = u;
		object = o;
		weight = r;
	}
}
