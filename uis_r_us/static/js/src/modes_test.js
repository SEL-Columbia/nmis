module("Modes testing", {
	setup: function(){
		Modes.clear();
		Modes.init({
				level: ["lga", "country"],
				sector: ["health", "education"]
			}, {
				preventModes: ["level:lga,sector:overview"]
			});
	}
});
test("Simple mode states", function(){
	equal(Modes.modeString(), "level:lga,sector:health");
	Modes.setMode("sector", "education");
	equal(Modes.modeString(), "level:lga,sector:education");
	Modes.setMode("level", "country");
	equal(Modes.modeString(), "level:country,sector:education");
});
test("Mode states trigger actions", function(){
	var i = 0;
	equal(Modes.modeString(), "level:lga,sector:health");
	Modes.listen("level:country", function(){
		i++;
	});
	Modes.setMode("level", "country");
	equal(i, 1);
});
test("Mode states trigger actions", function(){
	var i = 0;
	equal(Modes.modeString(), "level:lga,sector:health");
	Modes.listen("level:country", function(){
		i++;
	});
	Modes.setMode("level", "country");
	equal(i, 1);
});
test("Actions are preventable", function(){
	var oldModeString = "level:lga,sector:health";
	equal(oldModeString, Modes.modeString());
	equal(Modes.modeString(), oldModeString);
	Modes.listen("level:country,sector:health", function(){
		this.stopChange = true;
	});
	Modes.setMode("level", "country");
	equal(Modes.modeString(), oldModeString);
});