module dregs.codetermine;

import std.math,
       std.stdio,
       dregs.core;

struct CoDetermination(alias This, alias ObjectReputation, alias UserDivergence, alias UserReputation,
                       UserID = size_t, ObjectID = size_t, Reputation = double)
{
	private immutable Reputation convergence_;
	private Rating!(UserID, ObjectID, Reputation)[] ratings_;
	private Reputation[] reputationUser_;
	private Reputation[] reputationObject_;
	private Reputation[] reputationObjectOld_;
	private size_t[] userLinks_;

	mixin This!(UserID, ObjectID, Reputation);             // good God, the constructor can be a template mixin!!
	mixin ObjectReputation!(UserID, ObjectID, Reputation); // calculates object reputation based on ratings & user reputation
	mixin UserDivergence!(UserID, ObjectID, Reputation);   // calculates divergence of user opinions from consensus
	mixin UserReputation!(UserID, ObjectID, Reputation);   // calculates user reputation based on divergence from consensus

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

	final pure nothrow Reputation[] reputationUser()
	{
		return reputationUser_;
	}

	final pure nothrow Reputation[] reputationObject()
	{
		return reputationObject_;
	}
}


mixin template ThisYZLM(UserID = size_t, ObjectID = size_t, Reputation = double)
{
	private immutable Reputation exponent_;
	private immutable Reputation minDivergence_;

	this(Reputation convergence, Reputation exponent, Reputation minDivergence)
	in
	{
		assert(convergence > 0);
		assert(exponent >= 0);
		assert(minDivergence > 0);
	}
	body
	{
		convergence_ = convergence;
		exponent_ = exponent;
		minDivergence_ = minDivergence;
	}
}


mixin template ThisDKVDexp(UserID = size_t, ObjectID = size_t, Reputation = double)
{
	private immutable Reputation exponent_;

	this(Reputation convergence, Reputation exponent)
	in
	{
		assert(convergence > 0);
		assert(exponent >= 0);
	}
	body
	{
		convergence_ = convergence;
		exponent_ = exponent;
	}
}


mixin template ThisDKVDlinear(UserID = size_t, ObjectID = size_t, Reputation = double)
{
	private immutable Reputation minDivergence_;

	this(Reputation convergence, Reputation minDivergence)
	in
	{
		assert(convergence > 0);
		assert(minDivergence > 0);
	}
	body
	{
		convergence_ = convergence;
		minDivergence_ = minDivergence;
	}
}


mixin template ObjectReputationInitBasic(UserID = size_t, ObjectID = size_t, Reputation = double)
{
	private final pure nothrow void objectReputationInit()
	{
		weightSum_.length = reputationObject_.length;
		objectReputation;
	}
}


mixin template ObjectReputationWeightedAverage(UserID = size_t, ObjectID = size_t, Reputation = double)
{
	private Reputation[] weightSum_;

	mixin ObjectReputationInitBasic!(UserID, ObjectID, Reputation);

	private final pure nothrow void objectReputation()
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
}


mixin template UserDivergenceSquare(UserID = size_t, ObjectID = size_t, Reputation = double)
{
	private final pure nothrow userDivergence()
	{
		reputationUser_[] = 0;

		foreach(r; ratings_) {
			Reputation aux =  r.weight - reputationObject_[r.object];
			reputationUser_[r.user] += aux*aux;
		}
	}
}


mixin template UserReputationInitBasic(UserID = size_t, ObjectID = size_t, Reputation = double)
{
	private final pure nothrow void userReputationInit()
	{
		userLinks_.length = reputationUser_.length;
		userLinks_[] = 0;

		foreach(r; ratings_)
			userLinks_[r.user]++;

		reputationUser_[] = 1.0;
	}
}


mixin template UserReputationInversePower(UserID = size_t, ObjectID = size_t, Reputation = double)
{
	private size_t[] userLinks_;

	mixin UserReputationInitBasic!(UserID, ObjectID, Reputation);

	private final pure nothrow void userReputation()
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
}


mixin template UserReputationExponential(UserID = size_t, ObjectID = size_t, Reputation = double)
{
	private size_t[] userLinks_;

	mixin UserReputationInitBasic!(UserID, ObjectID, Reputation);

	private final pure nothrow void userReputation()
	in
	{
		assert(exponent_ >= 0);
	}
	body
	{
		foreach(size_t u, ref Reputation rep; reputationUser_) {
			if(userLinks_[u] > 0)
				rep = exp( -exponent_ * (rep/userLinks_[u]) );
			else
				rep = 0;  // probably unnecessary, but safer.
		}
	}
}


mixin template UserReputationLinear(UserID = size_t, ObjectID = size_t, Reputation = double)
{
	private size_t[] userLinks_;

	mixin UserReputationInitBasic!(UserID, ObjectID, Reputation);

	private final pure nothrow void userReputation()
	in
	{
		assert(minDivergence_ > 0);
	}
	body
	{
		Reputation maxDivergence = 0;

		foreach(size_t u, Reputation rep; reputationUser_) {
			if(userLinks_[u] > 0) {
				Reputation aux = rep/userLinks_[u];
				if(aux > maxDivergence)
					maxDivergence = aux;
			}
		}

		foreach(size_t u, ref Reputation rep; reputationUser_) {
			if(userLinks_[u] > 0)
				rep = 1 - (rep/userLinks_[u]) / (maxDivergence + minDivergence_);
			else
				rep = 0;  // probably unnecessary, but safer.
		}
	}
}


alias CoDetermination!(ThisYZLM, ObjectReputationWeightedAverage, UserDivergenceSquare, UserReputationInversePower,
                       size_t, size_t, double) YZLM;

alias CoDetermination!(ThisDKVDexp, ObjectReputationWeightedAverage, UserDivergenceSquare, UserReputationExponential,
                       size_t, size_t, double) DKVDexp;

alias CoDetermination!(ThisDKVDlinear, ObjectReputationWeightedAverage, UserDivergenceSquare, UserReputationLinear,
                       size_t, size_t, double) DKVDlinear;

