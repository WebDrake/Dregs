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
	private Reputation[] reputationObjectOld_;

	mixin ObjectReputation!(UserID, ObjectID, Reputation); // calculates object reputation based on ratings & user reputation
	mixin UserDivergence!(UserID, ObjectID, Reputation);   // calculates divergence of user opinions from consensus
	mixin UserReputation!(UserID, ObjectID, Reputation);   // calculates user reputation based on divergence from consensus
	
	this(Reputation convergence, Reputation exponent, Reputation minDivergence)
	in
	{
		assert(convergence > 0);
		assert(minDivergence > 0);
	}
	body
	{
		convergence_ = convergence;
		exponent_ = exponent;
		minDivergence_ = minDivergence;
	}

	size_t reputation(ref Reputation[] reputationUser, ref Reputation[] reputationObject, ref Rating!(UserID, ObjectID, Reputation)[] ratings)
	in
	{
		assert(reputationUser.length > 0);
		assert(reputationObject.length > 0);
		assert(ratings.length > 0);
	}
	body
	{
		reputationObjectOld_.length = reputationObject.length;
		
		userReputationInit(reputationUser, reputationObject, ratings);
		objectReputationInit(reputationUser, reputationObject, ratings);

		Reputation diff;
		size_t iterations = 0;

		do {
			userDivergence(reputationUser, reputationObject, ratings);
			userReputation(reputationUser, reputationObject, ratings);

			reputationObjectOld_[] = reputationObject[];
			objectReputation(reputationUser, reputationObject, ratings);
			diff = 0;
			foreach(size_t o, Reputation rep; reputationObject) {
				auto aux = rep - reputationObjectOld_[o];
				diff += aux*aux;
			}
			++iterations;
		} while (diff > convergence_);

		writeln("Exited in ", iterations, " iterations with diff = ", diff, " < ", convergence_);

		return iterations;
	}
}


mixin template ObjectReputationWeightedAverage(UserID = size_t, ObjectID = size_t, Reputation = double)
{
	private Reputation[] weightSum_;
	
	final pure nothrow void objectReputation(ref Reputation[] reputationUser, ref Reputation[] reputationObject, ref Rating!(UserID, ObjectID, Reputation)[] ratings)
	{
		weightSum_.length = reputationObject.length;
		weightSum_[] = 0;
		reputationObject[] = 0;

		foreach(r; ratings) {
			reputationObject[r.object] += reputationUser[r.user] * r.weight;
			weightSum_[r.object] += reputationUser[r.user];
		}
		
		foreach(size_t o, ref Reputation rep; reputationObject)
			rep /= (weightSum_[o] > 0) ? weightSum_[o] : 1;
	}

	final pure nothrow void objectReputationInit(ref Reputation[] reputationUser, ref Reputation[] reputationObject, ref Rating!(UserID, ObjectID, Reputation)[] ratings)
	{
		weightSum_.length = reputationObject.length;
		objectReputation(reputationUser, reputationObject, ratings);
	}
}


mixin template UserDivergenceSquare(UserID = size_t, ObjectID = size_t, Reputation = double)
{
	final pure nothrow userDivergence(ref Reputation[] reputationUser, ref Reputation[] reputationObject, ref Rating!(UserID, ObjectID, Reputation)[] ratings)
	{
		reputationUser[] = 0;

		foreach(r; ratings) {
			Reputation aux =  r.weight - reputationObject[r.object];
			reputationUser[r.user] += aux*aux;
		}
	}
}


mixin template UserReputationInversePower(UserID = size_t, ObjectID = size_t, Reputation = double)
{
	private size_t[] userLinks_;
	
	final pure nothrow void userReputation(ref Reputation[] reputationUser, ref Reputation[] reputationObject, ref Rating!(UserID, ObjectID, Reputation)[] ratings)
	in
	{
		assert(exponent_ >= 0);
	}
	body
	{
		foreach(size_t u, ref Reputation rep; reputationUser) {
			if(userLinks_[u] > 0)
				rep = ((rep / userLinks_[u]) + minDivergence_) ^^ (-exponent_);
			else
				rep = 0;  // probably unnecessary, but safer.
		}
	}

	final pure nothrow void userReputationInit(ref Reputation[] reputationUser, ref Reputation[] reputationObject, ref Rating!(UserID, ObjectID, Reputation)[] ratings)
	{
		userLinks_.length = reputationUser.length;
		userLinks_[] = 0;
		
		foreach(r; ratings)
			userLinks_[r.user]++;

		reputationUser[] = 1.0;
	}
}


alias CoDetermination!(ObjectReputationWeightedAverage, UserDivergenceSquare, UserReputationInversePower,
                       size_t, size_t, double)
	Yzlm;
