import std.math, std.random, std.stdio;

import dregs.core, dregs.codetermine;

void main()
{
	Rating!(size_t, size_t, double)[] ratings;
	double[] objectQuality, userError, userReputationInit;
	Mt19937 rng;
	size_t users = 1000;
	size_t objects = 1000;
	auto yzlm = new Yzlm(1e-24, 0.8, 1e-36);
	
	rng.seed(1001);

	objectQuality.length = objects;
	userError.length = users;

	size_t iterations;
	size_t iterTotal = 0;
	
	foreach(size_t i; 0..100) {
		foreach(ref double Q; objectQuality)
			Q = uniform(0.0, 10.0, rng);
		
		foreach(ref double sigma2; userError)
			sigma2 = uniform(0.0, 1.0, rng);

		assumeSafeAppend(ratings);

		ratings.length = 0;

		foreach(size_t object, ref double Q; objectQuality)
			foreach(size_t user, ref double sigma2; userError)
				ratings ~= new Rating!(size_t, size_t, double) (user, object, uniform(Q-sigma2, Q+sigma2, rng));

		writeln("We now have ", ratings.length, " ratings.");

		userReputationInit.length = users;
		userReputationInit[] = 1.0;
		
		iterations = yzlm.reputation(users, objects, ratings, userReputationInit);
		iterTotal += iterations;

		double deltaQ = 0;
		foreach(size_t object, ref const(double) rep; yzlm.reputationObject)
			deltaQ += (rep - objectQuality[object]) ^^ 2.0;
		deltaQ = sqrt(deltaQ/objectQuality.length);

		writeln("[",i,"] Exited in ", iterations, " iterations with error = ", deltaQ);
	}
}
