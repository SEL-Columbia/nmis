var data = [];
var sectors = ["agriculture", "education", "hlth", "water'"];
_.times(40, function(i){
    data.push({
        sector: sectors[i%4],
        something: i%3==0
    });
});

test("Tabulations work with sample data", function(){
    ok(Tabulation.init(data), "Tabulation.init(data) returned true");
    equal(Tabulation.bySector().length, 40);
    deepEqual(Tabulation.sectorSlug("education", "something"), {
        'false': 7,
        'true': 3
    }, "Tabulation.sectorSlug correctly calculates the tabulations.");
    deepEqual(Tabulation.sectorSlugAsArray("education", "something"),
            [
                {
                    occurrences: 'false',
                    value: 7
                },
                {
                    occurrences: 'true',
                    value: 3
                }
            ], "Tabulation.sectorSlugAsArray (which is used once) maps the tabulations into an array.");
    deepEqual(Tabulation.sectorSlug("education", "something", ["true", "false", "maybe"]), {
        'true': 3,
        'false': 7,
        'maybe': 0
    }, "Tabulation.sectorSlug can receive a list of keys and will include values as 0 if not found.")
});
