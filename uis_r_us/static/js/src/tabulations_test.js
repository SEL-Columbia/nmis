var data = [];
var sectors_ = ["agriculture", "education", "hlth", "water'"];
_.times(40, function(i){ data.push({sector: sectors_[i%4], something: i%3==0}); });

var sectors;
$.ajax({url: '/static/tmp_sectors.json',async: false,dataType: 'json'})
    .done(function(_sectors){sectors = _sectors;});

module("Data", {
    setup: function(){
        Data.init(data, sectors);
    },
    teardown: function(){
        Data.clear();
    }
});

test("Data", function(){
    ok(Data.init(data, sectors), "Data.init() works");
    ok(Data.Tabulation !== undefined, "Tabulation exists");
});

test("Tabulations work with sample data", function(){
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

test("Sectors", function(){
    var sectorList = Sectors.all();
    equal(sectorList.length, 3);
    equal(Sectors.pluck('health').slug, 'health', "Sectors.pluck(slug) works.")
    log(sectorList[0].subGroups());
//    ok(, "Sectors.init(...) returns true");
});

