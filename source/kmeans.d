/**
 * License: Copyright (c) 2021 Yuri Moskov
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without modification, are permitted (subject to the limitations in the disclaimer below) provided that the following conditions are met:
 * + Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 * + Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 * + Neither the name of Yuri Moskov nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 */

import std.stdio, std.complex, std.array, std.algorithm.iteration, std.random, std.typecons: Tuple, tuple;

import configuration;

int main(string[] args) {
	import std.json, IDataAdapter;
	auto configuration = new Configuration(args);

	if (!configuration.helpWanted) {
		assert(configuration.numClusters <= configuration.numPoints);
		assert(configuration.numClusters > 0);

		// Prepare random generator
		auto rnd = Random(unpredictableSeed);

		Complex!real[] points, clusters;

		if (configuration.isRandom) {
			points.length = configuration.numPoints;
			seed!real(points);
		} else {
			points = configuration.points;
		}

		// Pick up random points
		clusters = points.randomShuffle(rnd)[0..configuration.numClusters];

		pure_run!real(points, clusters);
		auto outFile = stdout;
		if (configuration.outfilename != null) {
			outFile = File(configuration.outfilename, "wb");
		}
		createIDataAdapter(configuration.outDataAdapter, "").writeClusters(outFile, clusters);
	}
	return 0;
}

/***********************************
 * seed generate random points
 * Params:
 *      numClusters =     number of clusters
 *      numPoints =     number of points
 */

void seed(T)(ref Complex!T[] points)
{
	// Generate random points
	foreach(ref x; points) {
		x = complex(uniform(T(-200), T(200)), uniform(T(-200), T(200)));
	}
}

pragma(inline):
void kmean(T, Tuple)(ref Complex!T[] clusters, ref bool changed, Tuple t) pure
{
	import std.math: isNaN;

	// Calculate cluster center
	Complex!T meanInCluster = ((Complex!T[] a) pure => (a.sum()/a.length))(t[1].map!(a => a.point).array);
	if (!isNaN(meanInCluster.re) && !isNaN(meanInCluster.im)) {
		if (meanInCluster != clusters[t[0]]) {
			// Move cluster center if new value doesn't equal old and isn't NaN.
			clusters[t[0]] = meanInCluster;
			changed = true;
		}
	}
}

/***********************************
 * pure_run K-Means clustering.
 * Params:
 *      points =     array of points
 *      clusters =     array of clusters
 */

int pure_run(T)(ref Complex!T[] points, ref Complex!T[] clusters) pure
in (points.length > 0)
in (clusters.length > 0)
out (result) {
	assert(result > 0);
}
do {
	import std.algorithm;
	int numInterations;
	bool changed = false;

	do {
		// Obviously: Reset changed and increment numInterations
		numInterations++;
		changed = false;

		points.map!(point => tuple!("point", "clusterId")(point, clusters.map!(cluster => abs(point-cluster)).minIndex)) // Find cluster of each point
	       .array.sort!"a.clusterId<b.clusterId".chunkBy!(a => a.clusterId) // group points by cluster they belong to
		     .each!(r => kmean!T(clusters, changed, r)); // calculate each cluster center and track changes

	} while (changed); // do while any of cluster center was moved during iteration. Cycle is finite.
	return numInterations;
}

