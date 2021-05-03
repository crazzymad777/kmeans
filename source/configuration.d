/**
 * License: Copyright (c) 2021 Yuri Moskov
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without modification, are permitted (subject to the limitations in the disclaimer below) provided that the following conditions are met:
 * + Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 * + Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 * + Neither the name of Yuri Moskov nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 */

import std.complex, IDataAdapter;

pragma(inline):
auto getArg(T)(ref string[] args, int N, T defaultValue) pure @safe {
	import std.conv;
	return args.length > N ? to!T(args[N]) : defaultValue;
}

class Configuration {
public:
	this(string[] args) {
		import std.algorithm, std.array, std.json, std.getopt, std.stdio, std.file: readText;

		auto helpInformation = getopt(args, "random|r", "generates random points", &m_isRandom, "clusters|c", "number of clusters (with --random & CSV)", &m_numClusters, "points|p", "number of points (works only with --random)", &m_numPoints, "input|i", "input filename (stdin if not specified)", &m_filename, "output|o", "output filename (stdout if not specified)", &m_outfilename, "adapter|d", "data adapter (JSON, CSV)", &m_dataAdapter, "input-adapter|id", "input data adapter (override common)", &m_inputDataAdapter, "output-adapter|od", "output data adapter (override common)", &m_outputDataAdapter);

		m_helpWanted = helpInformation.helpWanted;

		if (helpInformation.helpWanted)
		{
			defaultGetoptPrinter(args[0] ~ " [OPTIONS]", helpInformation.options);
			m_isRandom = true;
		} else {
			if (m_dataAdapter == DataAdapterType.NotSpecified) {
				m_dataAdapter = DataAdapterType.JSON;
			}
			if (m_inputDataAdapter == DataAdapterType.NotSpecified) {
				m_inputDataAdapter = m_dataAdapter;
			}
			if (m_outputDataAdapter == DataAdapterType.NotSpecified) {
				m_outputDataAdapter = m_dataAdapter;
			}

			if (!m_isRandom) {
				auto content = m_filename != null ? m_filename.readText : stdin.byLineCopy().array().fold!((a, b) => a ~ b);
				auto dataInterface = createIDataAdapter(getDataAdapterType(m_inputDataAdapter), content);

				if (!dataInterface.onlyPoints()) {
					m_numClusters = dataInterface.readProperty("clusters");
				}

				m_points = dataInterface.readPoints();
			}
		}
	}
	@property points() { return cast(Complex!real[])m_points; }
	@property numClusters() { return m_numClusters; }
	@property numPoints() { return m_numPoints; }
	@property isRandom() { return m_isRandom; }
	@property helpWanted() { return m_helpWanted; }
	@property outfilename() { return m_outfilename; }
	@property outDataAdapter() { return getDataAdapterType(m_outputDataAdapter); }
private:
	string getDataAdapterType(DataAdapterType t) {
		if (t == DataAdapterType.JSON) return "JSON";
		if (t == DataAdapterType.CSV) return "CSV";
		return "JSON";
	}

	long m_numClusters = 5;
	long m_numPoints = 500;
	void[] m_points;
	string m_precision;
	string m_filename = null;
	string m_outfilename = null;
	enum DataAdapterType {NotSpecified, JSON, CSV};
	DataAdapterType m_dataAdapter = DataAdapterType.NotSpecified;
	DataAdapterType m_inputDataAdapter = DataAdapterType.NotSpecified;
	DataAdapterType m_outputDataAdapter = DataAdapterType.NotSpecified;
	bool m_isRandom;
	bool m_helpWanted;
}

