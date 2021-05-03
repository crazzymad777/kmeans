/**
 * License: Copyright (c) 2021 Yuri Moskov
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without modification, are permitted (subject to the limitations in the disclaimer below) provided that the following conditions are met:
 * + Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 * + Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 * + Neither the name of Yuri Moskov nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 */

import std.complex, std.file, std.stdio;

interface IDataAdapter {
public:
	bool onlyPoints();
	int readProperty(string propertyName);
	Complex!real[] readPoints();
	void writeClusters(File file, Complex!real[] clusters);
}

IDataAdapter createIDataAdapter(string typename, string content) {
	if (typename == "JSON") {
		return new JSONDataAdapter(content);
	} else if (typename == "CSV") {
		return new CSVDataAdapter(content);
	}

	return new JSONDataAdapter(content);
}

class JSONDataAdapter : IDataAdapter {
	import std.json;

public:
	this(string JSONContent) {
		jsonRoot = parseJSON(JSONContent);
	}

	override bool onlyPoints() {
		return false;
	}

	override int readProperty(string propertyName) {
		return jsonRoot[propertyName].get!int();
	}

	override Complex!real[] readPoints() {
		import std.algorithm, std.array;

		return jsonRoot["points"].array.map!(x => Complex!real(x[0].get!real, x[1].get!real)).array;
	}

	override void writeClusters(File file, Complex!real[] clusters) {
		import std.algorithm, std.array;

		JSONValue value = ["clusters": clusters.map!(x => [x.re, x.im]).array];

		file.writeln(value.toJSON());
	}

private:
	JSONValue jsonRoot;
}

class CSVDataAdapter : IDataAdapter {
	import std.csv;

public:
	this(string CSVContent) {
		csvTable = CSVContent;
	}

	override bool onlyPoints() {
		return true;
	}

	override int readProperty(string propertyName) {
		return 0;
	}

	override Complex!real[] readPoints() {
		import std.typecons, std.algorithm, std.array;

		Complex!real[] r;
		r = csvReader!(Tuple!(real, real))(csvTable).map!(x => Complex!real(x[0], x[1])).array;
		return r;
	}

	override void writeClusters(File file, Complex!real[] clusters) {
		import std.algorithm, std.conv;

		clusters.map!(x => to!string(x.re) ~ ", " ~ to!string(x.im)).each!(x => file.writeln(x));
	}

private:
	string csvTable;
}

