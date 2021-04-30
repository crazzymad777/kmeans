/**
 * License: Copyright (c) 2021 Yuri Moskov
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without modification, are permitted (subject to the limitations in the disclaimer below) provided that the following conditions are met:
 * + Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 * + Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 * + Neither the name of Yuri Moskov nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 */

import std.stdio, std.complex, std.array, std.typecons: Tuple, tuple;

auto getArg(T)(ref string[] args, int N, T defaultValue) pure @safe {
	import std.conv;
	return args.length > N ? to!T(args[N]) : defaultValue;
};

int main(string[] args) @safe {
	auto filename = getArg!string(args, 1, "--random"), numClusters = getArg!int(args, 2, 5), numPoints = getArg!int(args, 3, 500);

	seedAndRun!real(numClusters, numPoints);
	return 0;
}

/***********************************
 * seedAndRun generate random points and start K-means clustering.
 * Params:
 *      numClusters =     number of clusters
 *      numPoints =     number of points
 */

void seedAndRun(T)(int numClusters = 5, int numPoints = 500) @safe
in (numClusters > 0)
in (numPoints > 0)
do {
	import std.random;
	// Prepare random generator
	auto rnd = Random(unpredictableSeed);

	Complex!T[] points;
	points.length = numPoints;

	// Generate random points
	foreach(ref x; points) {
		x = complex(uniform(T(-200), T(200), rnd), uniform(T(-200), T(200), rnd));
	}

	// Pick up random points
	Complex!T[] clusters = points.randomShuffle(rnd)[0..numClusters];

	// Start K-means
	pure_run(points, clusters);
}

/***********************************
 * pure_run K-Means clustering.
 * Params:
 *      points =     array of points
 *      clusters =     array of clusters
 */

int pure_run(T)(ref Complex!T[] points, ref Complex!T[] clusters) pure @safe
in (points.length > 0)
in (clusters.length > 0)
out (result) {
	assert(result > 0);
}
do {
	import std.algorithm.iteration, std.algorithm.searching, std.range, std.math: isNaN;
	int numInterations;
	bool changed = false;

	long[] clusterOfPoint;
	clusterOfPoint.length = points.length;

	do {
		numInterations++;
		changed = 0;

		// Find cluster of point
		points.enumerate.each!(tuple => clusterOfPoint[tuple.index] = clusters.map!(cluster => abs(tuple.value-cluster)).minIndex);

		foreach (c, cluster; clusters) {
			// Find new cluster value
			Complex!T meanInCluster = ((Complex!T[] a) pure => (a.sum()/a.length))(points.enumerate.filter!(a => clusterOfPoint[a.index] == c).map!"a.value".array);

			// Set new value if it doesn't equal old and isn't NaN
			if (!isNaN(meanInCluster.re) && !isNaN(meanInCluster.im)) {
				if (meanInCluster != clusters[c]) {
					clusters[c] = meanInCluster;
					changed = true;
				}
			}
		}
	} while (changed);
	return numInterations;
}

