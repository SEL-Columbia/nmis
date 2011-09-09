var data;
$.ajax({
    url: '/static/tmp_data.json',
    dataType: 'json',
    async: false
}).done(function(d){
    data = d;
});

test("Tabulations work with sample data", function(){
    ok(Tabulation.init(data), "Tabulation.init(data) returned true");
    equal(Tabulation.bySector().length, 41);
    deepEqual(Tabulation.sectorSlug("education", "school_1kmplus_catchment_area"),
            {
                'true': 19,
                'false': 4
            });
});
