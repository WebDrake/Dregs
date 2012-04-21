import std.math, std.random, std.stdio;

import dregs.core, dregs.codetermine;

struct RatingIsh
{
	size_t user;
	size_t object;
	double weight;

	this(size_t u, size_t o, double w)
	{
		user = u;
		object = o;
		weight = w;
	}
}

void main()
{
	Rating!(size_t, size_t, double)[] ratings;
	double[] objectQuality;
	double[] userError;
	Mt19937 rng;
	auto yzlm = new Yzlm(1e-24, 0.8, 1e-36);
	
	rng.seed(1001);

	objectQuality.length = 1000;
	userError.length = 1000;

	size_t iterTotal = 0;

	ratings.length = userError.length * objectQuality.length;
	foreach(size_t i; 0..100) {
		foreach(ref double Q; objectQuality)
			Q = uniform(0.0, 10.0, rng);
		
		foreach(ref double sigma2; userError)
			sigma2 = uniform(0.0, 1.0, rng);

		assumeSafeAppend(ratings);

		size_t pos = 0;
		
		foreach(size_t object, double Q; objectQuality) {
			foreach(size_t user, double sigma2; userError) {
				ratings[pos] = Rating!(size_t, size_t, double)(user, object, uniform(Q-sigma2, Q+sigma2, rng));
				pos++;
			}
		}

		ratings.length = pos;

		writeln("[", i, "] Generated ", ratings.length, " ratings.");

		size_t iterations = yzlm.reputation(userError.length, objectQuality.length, ratings);
		iterTotal += iterations;

		double deltaQ = 0;
		foreach(size_t object, double rep; yzlm.reputationObject)
			deltaQ += (rep - objectQuality[object]) ^^ 2.0;
		deltaQ = sqrt(deltaQ/objectQuality.length);

		writeln("Error in quality estimate: ", deltaQ);
		writeln("--------");
	}

	writeln("Total iterations: ", iterTotal);
}
