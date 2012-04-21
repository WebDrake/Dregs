module dregs.codetermine;

import std.math,
       std.stdio,
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
	private Reputation[] reputationObjectOld_;
	private size_t[] userLinks_;

	mixin ObjectReputation!(UserID, ObjectID, Reputation); // calculates object reputation based on ratings & user reputation
	mixin UserDivergence!(UserID, ObjectID, Reputation);   // calculates divergence of user opinions from consensus
	mixin UserReputation!(UserID, ObjectID, Reputation);   // calculates user reputation based on divergence from consensus
	
	this(Reputation convergence, Reputation exponent, Reputation minDivergence = 0.0)
	in
	{
		assert(convergence > 0);
		assert(minDivergence >= 0);
	}
	body
	{
		convergence_ = convergence;
		exponent_ = exponent;
		minDivergence_ = minDivergence;
	}

	size_t reputation(size_t users, size_t objects, Rating!(UserID, ObjectID, Reputation)[] ratings)
	in
	{
		assert(users > 0);
		assert(objects > 0);
		assert(ratings.length > 0);
	}
	body
	{
		reputationUser_.length = users;
		reputationObject_.length = objects;
		reputationObjectOld_.length = objects;
		ratings_ = ratings;
		
		userReputationInit;
		objectReputationInit;

		Reputation diff;
		size_t iterations = 0;

		do {
			userDivergence;
			userReputation;

			reputationObjectOld_[] = reputationObject_[];
			objectReputation;
			diff = 0;
			foreach(size_t o, Reputation rep; reputationObject_) {
				auto aux = rep - reputationObjectOld_[o];
				diff += aux*aux;
			}
			++iterations;
		} while (diff > convergence_);

		writeln("Exited in ", iterations, " iterations with diff = ", diff);

		return iterations;
		return 0;
	}
	     

	final pure nothrow ref Reputation[] reputationUser()
	{
		return reputationUser_;
	}

	final pure nothrow ref Reputation[] reputationObject()
	{
		return reputationObject_;
	}
}


mixin template ObjectReputationWeightedAverage(UserID = size_t, ObjectID = size_t, Reputation = double)
{
	private Reputation[] weightSum_;
	
	final pure nothrow void objectReputation()
	in
	{
		assert(weightSum_.length == reputationObject_.length);
	}
	body
	{
		weightSum_[] = 0;
		reputationObject_[] = 0;

		foreach(r; ratings_) {
			reputationObject_[r.object] += reputationUser_[r.user] * r.weight;
			weightSum_[r.object] += reputationUser_[r.user];
		}
		
		foreach(size_t o, ref Reputation rep; reputationObject_)
			rep /= (weightSum_[o] > 0) ? weightSum_[o] : 1;
	}

	final pure nothrow void objectReputationInit()
	{
		weightSum_.length = reputationObject_.length;
		objectReputation;
	}
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
		assert(minDivergence_ > 0);
		assert(userLinks_.length == reputationUser_.length);
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

		reputationUser_[] = 1.0;
	}
}


alias CoDetermination!(ObjectReputationWeightedAverage, UserDivergenceSquare, UserReputationInversePower,
                       size_t, size_t, double)
	Yzlm;
