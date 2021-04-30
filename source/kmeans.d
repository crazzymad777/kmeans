/**
 * License: Copyright (c) 2021 Yuri Moskov
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without modification, are permitted (subject to the limitations in the disclaimer below) provided that the following conditions are met:
 * + Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 * + Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 * + Neither the name of Yuri Moskov nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 */

import std.json, std.stdio, std.complex, std.array, std.algorithm.iteration, std.random, std.typecons: Tuple, tuple;

pragma(inline):
auto getArg(T)(ref string[] args, int N, T defaultValue) pure @safe {
	import std.conv;
	return args.length > N ? to!T(args[N]) : defaultValue;
};

int main(string[] args) {
	import std.file: readText;

	auto filename = getArg!string(args, 1, "--random");

	if (filename == "--random") {
		seedAndRun!real(5, 500);
	} else {
		// Prepare random generator
		auto rnd = Random(unpredictableSeed);

		auto jsonRoot = filename.readText.parseJSON;
		auto numClusters = jsonRoot["clusters"].integer;
		auto points = jsonRoot["points"].array.map!(x => Complex!real(x[0].get!real, x[1].get!real)).array;

		// Pick up random points
		Complex!real[] clusters = points.randomShuffle(rnd)[0..numClusters];

		pure_run(points, clusters);
		JSONValue output = ["clusters": clusters.map!(x => [x.re, x.im]).array];
		writeln(toJSON(output));
	}
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
	JSONValue output = ["clusters": clusters.map!(x => [x.re, x.im]).array];
	writeln(toJSON(output));
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
	import std.algorithm.searching, std.range, std.math: isNaN;
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

