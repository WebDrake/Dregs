module dregs.codetermine;

import std.math,
       dregs.core;

struct CoDetermination(alias ObjectReputation, alias UserDivergence, alias UserReputation,
                       UserID = size_t, ObjectID = size_t, Reputation = double)
{
	private immutable Reputation convergence_;
	private immutable Reputation exponent_;
	private immutable Reputation minDivergence_;
	private Rating!(UserID, ObjectID, Reputation)[] ratings_;
	private Reputation[] reputationUser_;
	private Reputation[] reputationObject_;
	private size_t[] userLinks_;

	mixin ObjectReputation!(UserID, ObjectID, Reputation); // calculates object reputation based on ratings & user reputation
	mixin UserDivergence!(UserID, ObjectID, Reputation);   // calculates divergence of user opinions from consensus
	mixin UserReputation!(UserID, ObjectID, Reputation);   // calculates user reputation based on divergence from consensus
	
	this(size_t users, size_t objects,
	     Rating!(UserID, ObjectID, Reputation)[] ratings, Reputation[] reputationUserInit,
	     Reputation convergence, Reputation exponent, Reputation minDivergence)
	in
	{
		assert(users > 0);
		assert(objects > 0);
		assert(reputationUserInit.length == users);
		assert(convergence > 0);
		assert(minDivergence > 0);
	}
	body
	{
		reputationUser_.length = users;
		reputationObject_.length = objects;
		ratings_[] = ratings[];
		reputationUser_[] = reputationUserInit[];
		convergence_ = convergence;
		exponent_ = exponent;
		minDivergence_ = minDivergence;
	}
}


mixin template ObjectReputationWeightedAverage(UserID = size_t, ObjectID = size_t, Reputation = double)
{
	private Reputation[] weightSum_;
	
	final pure nothrow void objectReputation()
	{
		weightSum_.length = reputationObject_.length;
		weightSum_[] = 0;

		foreach(r; ratings_) {
			reputationObject_[r.object] += reputationUser_[r.user] * r.weight;
			weightSum_[r.object] += reputationUser_[r.user];
		}
		
		foreach(size_t o, ref Reputation rep; reputationObject_)
			rep /= (weightSum_[o] > 0) ? weightSum_[o] : 1;
	}

	final pure nothrow void objectReputationInit() {};
}


mixin template UserDivergenceSquare(UserID = size_t, ObjectID = size_t, Reputation = double)
{
	final pure nothrow userDivergence()
	{
		reputationUser_[] = 0;

		foreach(r; ratings_) {
			Reputation aux =  r.weight - reputationObject_[r.object];
			reputationUser_[r.user] += aux*aux;
		}
	}
}


mixin template UserReputationInversePower(UserID = size_t, ObjectID = size_t, Reputation = double)
{
	private size_t[] userLinks_;
	
	final pure nothrow void userReputation()
	in
	{
		assert(exponent_ >= 0);
	}
	body
	{
		foreach(size_t u, ref Reputation rep; reputationUser_) {
			if(userLinks_[u] > 0)
				rep = ((rep / userLinks_[u]) + minDivergence_) ^^ (-exponent_);
			else
				rep = 0;  // probably unnecessary, but safer.
		}
	}

	final pure nothrow void userReputationInit()
	{
		userLinks_.length = reputationUser_.length;
		userLinks_[] = 0;
		
		foreach(r; ratings_)
			userLinks_[r.user]++;
	}
}


alias CoDetermination!(ObjectReputationWeightedAverage, UserDivergenceSquare, UserReputationInversePower,
                       size_t, size_t, double)
	Yzlm;
