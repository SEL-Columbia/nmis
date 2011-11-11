// selfRemovingModule adds an element to the page and
// removes it from the page if the test is not being run alone.
function selfRemovingModule(str, obj) {
    var setup = obj.setup || function(){},
        teardown = obj.teardown || function(){};
    function paramHas(q) {
        return !!QUnit.urlParams.filter && QUnit.urlParams.filter.indexOf(q) !== -1;
    }
    var o = _.extend({}, obj, {
        setup: function(){
            this.elem = $('<div />')
                    .appendTo('div.page-header');
            setup.apply(this, arguments);
        },
        teardown: function(){
            teardown.apply(this, arguments);
            if(!paramHas(str)) { this.elem.remove(); }
        }
    });
    module(str, o);
}

var sectors2 = sampleData.facility_variables.sectors;

var sl = sectors2.length, sli = 0;
var data2 = _.map(sampleData.data.facilities, function(i, key){
    return _.extend({}, i, {
        '_uid': key,
        'sector': sectors2[sli++ % sl].slug
    });
});

module("nmis", {
    setup: function(){
        NMIS.init(data, {
            iconSwitcher: false,
            sectors: sectors
        });
    },
    teardown: function(){
        NMIS.clear();
    }
});

test("nmis", function(){
    ok(NMIS.init(data2, {
        iconSwitcher: false,
        sectors: sectors2
    }), "NMIS.init() works");
    ok(NMIS.Tabulation !== undefined, "Tabulation exists");
});

test("tabulations_work", function(){
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

module("nmis_data", {
    setup: function(){}
});

test("nmis_data_validation", function(){
    NMIS.init(data2, {
        iconSwitcher: false,
        sectors: sectors2
    });
    ok(NMIS.validateData(), "Data is validated");
    equal(NMIS.dataForSector('health').length, 10, "Data for health has a length of x");
});

module("breadcrumbs", {
    setup: function (){
        Breadcrumb.clear();
        Breadcrumb.init('p.bc');
    },
    teardown: function (){
        Breadcrumb.clear();
    }
});

test("can_set_breadcrumb", function(){
    equal(0, Breadcrumb._levels().length);
    Breadcrumb.setLevels([
            ["Country", "/country"],
            ["State", "/country"],
            ["District", "/country/district"]
        ]);
    equal(3, Breadcrumb._levels().length);
    Breadcrumb.setLevel(2, ["LGA", "/country/lga"]);
    equal(3, Breadcrumb._levels().length);
    //draw is not tested.
    Breadcrumb.draw();
});

$('.page-header')
    .append($('<div />', {'id': 'display-window-wrap'}));

selfRemovingModule("page_elements", {
    setup: function(){
        DisplayWindow.clear();
        DisplayWindow.init('#display-window-wrap');
    },
    teardown: function(){}
});

// var MapControl = (function(){
//     var opts, elem, icons = [];
//     var loadStarted = false, loadFinished = false;
//     function init(_elem, _opts){
//         elem = $(_elem).eq(0);
//         opts = _.extend({}, {
//             //default options
//         },_opts);
//         if(!loadFinished && !loadStarted) {
//             //$.getScript
//             loadStarted = true;
//         }
//     }
//     window._gmapLoadFinished = function(){
//     }
//     function reset() {
//     }
//     function clear() {
//     }
//     function findIcons(s) {
//         _.filter(icons, function(){
//         });
//     }
//     function changeIconsStatus(_params) {
//         var params = _.extend({
//             show: [],
//             hide: [],
//             inactive: []
//         }, _params);
//         _.each(['show', 'hide', 'inactive'], function(t){
//             _.each(params[t], function(iconId){
//                 var i = findIcons(iconId);
//             });
//         });
//     }
//     function highlightIcons() {
//     }
//     return {
//         init: init,
//         clear: clear,
//         reset: reset
//     }
// })();

selfRemovingModule("map_icons", {
    setup: function(){
        this.simpleItems = {
            item1: {
                sector: 'health',
                name: 'Clinic'
            },
            item2: {
                sector: 'health',
                name: 'Dispensary'
            },
            item3: {
                sector: 'education',
                name: 'Primary School'
            },
            item4: {
                sector: 'education',
                name: 'Secondary School'
            }
        };
    }
});

test("icon_manager", function(){
    IconSwitcher.init({ items: this.simpleItems });

    equal(IconSwitcher.allShowing().length, 0, "items are hidden by default");

    // IconSwitcher.shiftStatus(callback) returns a status string
    IconSwitcher.shiftStatus(function(id, item) { return "normal"; });
    equal(IconSwitcher.allShowing().length, 4, "icons are showing");

    // if IconSwitcher.shiftStatus's function returns false, it will hide that item.
    IconSwitcher.shiftStatus(function(id, item) { return false; });
    equal(IconSwitcher.allShowing().length, 0, "icon is no longer showing");

    equal(IconSwitcher.all().length, 4, "All the items are returned");
    equal(IconSwitcher.filterStatus('normal').length, 0, "No items are normal");

    IconSwitcher.shiftStatus(function() { return "normal"; });
    equal(IconSwitcher.filterStatus('normal').length, 4, "All items are normal");
    
    //selectively set status
    IconSwitcher.shiftStatus(function(id, item) {
        return item.name == "Dispensary" ? "normal" : false;
    });
    equal(IconSwitcher.filterStatus('normal').length, 1, "Only dispensary has a normal status");
    equal(IconSwitcher.allShowing().length, 1, "Only dispensary is showing");

    //selectively set status
    IconSwitcher.shiftStatus(function(id, item) {
        return item.name !== "Dispensary" ? "normal" : false;
    });
    equal(IconSwitcher.filterStatus('normal').length, 3, "Only dispensary status !== normal");
    equal(IconSwitcher.allShowing().length, 3, "Only dispensary is not showing");
});

test("icon_manager_callbacks", function(){
    IconSwitcher.init({ items: this.simpleItems });
    //reset all status to hidden and status:undefined.
    var newCounter = 0,
        hideCounter = 0;
    IconSwitcher.setCallback('shiftMapItemStatus', function(){
        newCounter++;
    });
    IconSwitcher.setCallback('setMapItemVisibility', function(tf){
        if(!tf) {
            hideCounter++;
        }
    });
    IconSwitcher.shiftStatus(function(id, item) {
        return "normal";
    });
    equal(newCounter, 4, "New counter is incremented. (setCallback works)");
    equal(hideCounter, 0, "Hide counter hasn't incremented yet.");
    IconSwitcher.shiftStatus(function(id, item) {
        return false;
    });
    equal(hideCounter, 4, "Hide counter has incremented.");
});

selfRemovingModule("map_icons_with_real_data", {
    setup: function(){
        NMIS.init(data2, {
            iconSwitcher: false,
            sectors: sectors2
        });
        IconSwitcher.init({ items: data2 });
    },
    teardown: function(){
        IconSwitcher.clear();
        NMIS.clear();
    }
});

test("icon_manager2", function(){
    equal(IconSwitcher.all().length, 30, "Sample data has all items");
    equal(IconSwitcher.allShowing().length, 0, "no icons showing");
});

selfRemovingModule("table_builder", {
    setup: function(){
        NMIS.init(data, {
            iconSwitcher: false,
            sectors: sectors
        });
    },
    teardown: function(){
        NMIS.clear();
    }
});

test("build_for_health", function(){
    FacilityTables.createForSectors(['education'])
        .appendTo(this.elem);
    FacilityTables.select('health', 'ss2');
    equal(this.elem.find('table').length, 1, "There is one table in the element.")
});

module("map_mgr", {});

asyncTest("mapmgr", function(){
    var loaded = false;
    ok(MapMgr.init({
        fake: true,
        fakeDelay: 0,
        loadCallbacks: [
            function(){
                ok(MapMgr.isLoaded(), "MapMgr is now loaded.");
                start();
            }
        ]
    }), "MapMgr is initted");
    ok(!MapMgr.isLoaded(), "MapMgr is not initially loaded.")
});

selfRemovingModule("sector_navigation", {
    setup: function(){
        NMIS.init(data, {
            iconSwitcher: false,
            sectors: sectors
        });
    },
    teardown: function(){
        NMIS.clear();
    }
})

test("sector_clicking_doesnt_reload_map", function(){
    log(this.elem.text("X"));
    FacilityTables.createForSectors(['education'])
        .appendTo(this.elem);
    FacilityTables.select('health', 'ss2');
    equal(this.elem.find('table').length, 1, "There is one table in the element.")
});