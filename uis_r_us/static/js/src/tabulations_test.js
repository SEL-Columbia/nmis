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
    deepEqual(Tabulation.sectorSlug("education", "something"),
            {
                'true': 3,
                'false': 7
            });
});
