$('.page-header').remove();


//lga.slug = "lga2";

NMIS.DisplayWindow.init(".content", {
    offsetElems: '.topbar .fill .container',
    sizeCookie: true,
    callbacks: {
        resize: [
            function(animate, sizeName){
                if(sizeName==="full") {
                    NMIS.DisplayWindow.showTitle('tables');
                } else {
                    NMIS.DisplayWindow.showTitle('bar');
                }
            }
        ]
    }
});

var wElems = NMIS.DisplayWindow.getElems();

NMIS.LocalNav.init(wElems.wrap, {
    sections: [
        [
            ["mode:summary", "LGA Summary", "#"],
            ["mode:facilities", "Facility Detail", "#"]
        ],
        [
            ["sector:overview", "Overview", "#"],
            ["sector:health", "Health", "#"],
            ["sector:education", "Education", "#"],
            ["sector:water", "Water", "#"]
        ]
    ]
});

NMIS.Breadcrumb.init("p.bc", {
    levels: [
        [state.name, "/nmis~/"],
        [lga.name, "/nmis~/"+state.slug+"/"+lga.slug+"/"]
    ]
});

var MapLoader = (function(){
    var maploaded = false, cbs = [];
    function init(_opts) {
        log("started map load");
    }
    function loaded() {
        log("Finished map load");
        maploaded = true;
        _.each(cbs, function(cb){
            cb();
        });
    }
    function addOnload(cb) {
        if(maploaded) {
            cb();
        } else {
            cbs.push(cb);
        }
    }
    return {
        init: init,
        loaded: loaded,
        addOnload: addOnload
    }
})();

var FacilitySelector = (function(){
    return function(params){
        var fId = params.id;
        NMIS.IconSwitcher.shiftStatus(function(id, item) {
            if(id === fId) {
                return "highlighted";
            } else if(item.status === "highlighted") {
                return "normal";
            }
        });
    }
})();

function prepFacilities(params) {
    var facilitiesMode = {name:"Facility Detail", slug:"facilities"};
	var e = {
	    state: state,
	    lga: lga,
	    mode: facilitiesMode,
	    sector: params.sector,
	    subsector: params.subsector,
	    indicator: params.indicator
	};
	var navSector = e.sector === undefined ? 'overview' : e.sector;
	var _sector;
	if(!!e.sector) {
	    _sector = { name: e.sector, slug: e.sector.toLowerCase() };
	}
	(function(){
	    function prepBreadcrumbValues(e, keys, env){
            var i, l, key, val, name, arr = [];
            for(i=0, l=keys.length; i < l; i++) {
                key = keys[i];
                val = e[key];
                if(val !== undefined) {
                    name = val.name || val.slug || val;
                    env[key] = val;
                    arr.push([name, NMIS.urlFor(env)])
                } else {
                    return arr;
                }
            }
            return arr;
        }
        var bcValues = prepBreadcrumbValues(e,
                        "state lga mode sector subsector indicator".split(" "),
                        {state:state,lga:lga});

	    NMIS.LocalNav.markActive(["mode:facilities", "sector:" + navSector]);
        NMIS.Breadcrumb.clear();
    	NMIS.Breadcrumb.setLevels(bcValues);
	})();
    NMIS.LocalNav.iterate(function(sectionType, buttonName, a){
        var env = {
            lga: lga,
            mode: facilitiesMode,
            state: state,
            sector: _sector
        };
        env[sectionType] = buttonName;
        a.attr('href', NMIS.urlFor(env));
    });
}

var _tIconSwitchedOn = false;
var zz = 0;

var itemStatii = {};
var itemzOnMap = {};

function launchFacilities(lgaData, variableData, params) {
    if(lgaData.profileData===undefined) { lgaData.profileData = {}; }
    if(lgaData.profileData.gps === undefined) {
        lgaData.profileData.gps = {
            value: "40.809587 -73.953223 183.0 4.0"
        };
    }
	var facilities = lgaData.facilities;
	var sectors = variableData.sectors;
	var e = {
	    sector: params.sector,
	    subsector: params.subsector,
	    indicator: params.indicator
	};

	NMIS.init(facilities, sectors);
	
	var boolMapLoad = true;

	if(boolMapLoad) {
	    MapMgr.init({
	        llString: lgaData.profileData.gps.value,
	        elem: wElems.elem0
	    });
	    MapMgr.addLoadCallback(function(){
            this.map = new google.maps.Map(this.elem.get(0), {
                zoom: 8,
                center: new google.maps.LatLng(this.ll.lat, this.ll.lng),
                mapTypeId: google.maps.MapTypeId[this.defaultMapType]
            });
	    });
	}

	if(!_tIconSwitchedOn) {
	    _tIconSwitchedOn = true;
	    NMIS.IconSwitcher.init({
    	    items: facilities
    	});
        MapLoader.init();

//    	NMIS.IconSwitcher.iterate(function(item, id){
//    	    item.status = "hidden";
//    	});
	}
	NMIS.IconSwitcher.setCallback('shiftMapItemStatus', function(item, id){
	    itemStatii[id] = item.status;
	});

	if(!e.sector) {
	    wElems.elem1content.empty();
	    NMIS.DisplayWindow.setTempSize("minimized", true);
        var displayTitle = "Facility Detail: "+lga.name+" Overview";
        NMIS.DisplayWindow.setTitle(displayTitle);
        NMIS.IconSwitcher.shiftStatus(function(id, item) {
            return "normal";
        });
    } else {
        NMIS.IconSwitcher.shiftStatus(function(id, item) {
            if(item.sector.toLowerCase()===e.sector.toLowerCase()) {
                return "normal";
            } else {
                return "inactive";
            }
        });
	    var _sector = NMIS.Sectors.pluck(e.sector);
        var displayTitle = "Facility Detail: "+lga.name+" " + _sector.name;
        NMIS.DisplayWindow.setTitle(displayTitle);
        NMIS.DisplayWindow.unsetTempSize(true);
        var tableElem = FacilityTables.createForSectors([e.sector], {
            callback: function(div){
                var pageTitle = $('<h1 />')
                            .addClass('facilities-content-title')
                            .hide()
                            .text(displayTitle);
                div.prepend(pageTitle);
                NMIS.DisplayWindow.addTitle('tables', pageTitle);
            },
            sectorCallback: function(sector, div, createNav, odiv) {
                createNav(sector, function(sg){
                    return NMIS.urlFor({
                        state: state.slug,
                        lga: lga.slug,
                        mode: 'facilities',
                        sector: sector.slug,
                        subsector: sg.slug
                    });
                }).prependTo(div);
            }
        });
        tableElem.delegate('tr', 'click', function(){
            FacilitySelector({id: $(this).data('facilityId')});
        });
        tableElem.appendTo(wElems.elem1content);
        if(!!e.subsector) FacilityTables.select(e.sector, e.subsector);
	}
}

var dashboard;
$(function(){
	var lgaData = DataLoader.fetch("/facilities/site/" + lgaUniqueSlug);
	var variableData = DataLoader.fetch("/facility_variables");
	function loadFacilities() {
	    var params = this.params;
	    if(params.sector === "overview") {
	        params.sector = undefined;
	    }
	    prepFacilities(params);
	    $.when(lgaData, variableData)
    		.done(function(req1, req2){
    		    var lgaData = req1[0];
                var variableData = req2[0];
                launchFacilities(lgaData, variableData, params);
    		});
	}
	function _pushAsDefined(obj, keyList) {
	    var key, i, l, arr = [], item;
	    for(i=0, l=keyList.length; i < l; i++) {
	        key = keyList[i];
	        item = obj[key];
            if(item !== undefined) {
                if(item===false) { return ["/error"]; }
                arr.push(item.slug === undefined ? item : item.slug);
	        } else {
	            return arr;
	        }
	    }
	}
	NMIS.urlFor = function(_o){
        var o = _.extend({
            //defaults
            root: '/nmis~',
            mode: 'summary'
        }, _o);
        if(!o.lga || !o.state) return "/error";
        return _pushAsDefined(o,
                        ["root", "state", "lga", "mode",
                        "sector", "subsector", "indicator"]).join('/');
    }
	dashboard = $.sammy(function(){
	    this.get("/nmis~/:state/:lga/facilities/?", loadFacilities);
	    this.get("/nmis~/:state/:lga/facilities/:sector/?", loadFacilities);
	    this.get("/nmis~/:state/:lga/facilities/:sector/:subsector/?", loadFacilities);
	    this.get("/nmis~/:state/:lga/facilities/:sector/:subsector/:indicator/?", loadFacilities);
	});
});
