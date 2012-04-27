import std.math, std.random, std.stdio,
       dregs.core, dregs.codetermine;

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
	auto yzlm = YZLM(1e-24, 0.8, 1e-36);
	auto dkvdLin = DKVDlinear(1e-24, 1e-36);
	auto dkvdExp = DKVDexp(1e-24, 0.8);
	
	rng.seed(1001);

	objectQuality.length = 1000;
	userError.length = 1000;

	size_t iterTotal = 0;

	ratings.length = userError.length * objectQuality.length;

	alias yzlm algorithm;

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

		CoDetResult result = algorithm.reputation(userError.length, objectQuality.length, ratings);
		writeln("Exited in ", result.iterations, " iterations with diff = ", result.diff);
		iterTotal += result.iterations;

		double deltaQ = 0;
		foreach(size_t object, double rep; algorithm.reputationObject)
			deltaQ += (rep - objectQuality[object]) ^^ 2.0;
		deltaQ = sqrt(deltaQ/objectQuality.length);

		writeln("Error in quality estimate: ", deltaQ);
		writeln("--------");
	}

	writeln("Total iterations: ", iterTotal);
}
