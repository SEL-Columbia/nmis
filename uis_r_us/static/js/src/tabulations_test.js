var data = [];
var sectors = [], _sectors = ["Agriculture", "Education", "Health", "Water"];
_.each(_sectors, function(s){
    sectors.push({
        name: s,
        slug: s.toLowerCase()
    });
});
_.times(40, function(i){
    data.push({
        sector: sectors[i%4].slug,
        something: i%3==0
    });
});

// var sectors;
// $.ajax({url: '/static/tmp_sectors.json',async: false,dataType: 'json'})
//     .done(function(_sectors){sectors = _sectors;});

module("NMIS", {
    setup: function(){
        NMIS.init(data, sectors);
    },
    teardown: function(){
        NMIS.clear();
    }
});

test("NMIS", function(){
    ok(NMIS.init(data, sectors), "NMIS.init() works");
    ok(NMIS.Tabulation !== undefined, "Tabulation exists");
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
    equal(sectorList.length, 4);
    equal(Sectors.pluck('health').slug, 'health', "Sectors.pluck(slug) works.")
});

// var data;
// $.ajax({url: '/static/tmp_data.json',async: false,dataType: 'json'})
//     .done(function(_data){data = _data;});

module("NMIS Data", {
    setup: function(){}
});

test("NMIS Data Validation", function(){
    NMIS.init(data, sectors);
    ok(NMIS.validateData(), "Data is validated");
    equal(NMIS.dataForSector('health').length, 10, "Data for health has a length of x");
});

// test("something", function(){
//     NMIS.FacilityTables.createForSectors(['health'])
//         .appendTo(this.elem);
//     NMIS.FacilityTables.select('health', 'malaria');
//     equal(this.elem.find('table').length, 1, "There is one table in the element.")
// })