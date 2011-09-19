var data = [];
var sectors_ = ["agriculture", "education", "hlth", "water'"];
_.times(40, function(i){ data.push({sector: sectors_[i%4], something: i%3==0}); });

var sectors;
$.ajax({url: '/static/tmp_sectors.json',async: false,dataType: 'json'})
    .done(function(_sectors){sectors = _sectors;});
    
var data2;
$.ajax({url: '/static/tmp_data.json',async: false,dataType: 'json'})
    .done(function(_data2){data2 = _data2;});

module("Table builder", {
    setup: function(){
        this.elem = $('<div />');
        $('#qunit-header').before(this.elem);
        NMIS.init(data2, sectors);
    },
    teardown: function(){
//        this.elem.remove();
    }
});

test("something", function(){
    FacilityTables.createForSectors(['health'])
        .appendTo(this.elem);
    FacilityTables.select('health', 'malaria');
    equal(this.elem.find('table').length, 1, "There is one table in the element.")
});