//FacilitySelector will probably end up in the NMIS object like all the other modules.
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



+function facilitiesDisplay(){
    var lgaData = DataLoader.fetch("/facilities/site/" + lgaUniqueSlug);
	var variableData = DataLoader.fetch("/facility_variables");

    function loadFacilities() {
        $('#conditional-content').hide();
	    var params = {};
	    _.each(this.params, function(param, pname){
	        if($.type(param)==="string" && param !== '') {
	            params[pname] = param.replace('/', '');
	        }
	    });
        if(params.sector === 'overview') {
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
	dashboard.get("/nmis~/:state/:lga/facilities/?", loadFacilities);
	dashboard.get("/nmis~/:state/:lga/facilities/:sector/?", loadFacilities);
    dashboard.get("/nmis~/:state/:lga/facilities/:sector/:subsector/?", loadFacilities);
    dashboard.get("/nmis~/:state/:lga/facilities/:sector/:subsector/:indicator/?", loadFacilities);
}();

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

function prepFacilities(params) {
    DisplayWindow.setVisibility(true);
    var facilitiesMode = {name:"Facility Detail", slug:"facilities"};
	var e = {
	    state: state,
	    lga: lga,
	    mode: facilitiesMode,
	    sector: Sectors.pluck(params.sector),
	};
	e.subsector = e.sector.getSubsector(params.subsector);
	e.indicator = e.sector.getIndicator(params.indicator);
    var bcValues = prepBreadcrumbValues(e,
                    "state lga mode sector subsector indicator".split(" "),
                    {state:state,lga:lga});
    NMIS.LocalNav.markActive(["mode:facilities", "sector:" + e.sector.slug]);
    NMIS.Breadcrumb.clear();
	NMIS.Breadcrumb.setLevels(bcValues);
    NMIS.LocalNav.iterate(function(sectionType, buttonName, a){
        var env = _.extend({}, e, {subsector: false});
        env[sectionType] = buttonName;
        a.attr('href', NMIS.urlFor(env));
    });
}

function launchFacilities(lgaData, variableData, params) {
    if(lgaData.profileData===undefined) { lgaData.profileData = {}; }
    if(lgaData.profileData.gps === undefined) {
        lgaData.profileData.gps = {
            value: "40.809587 -73.953223 183.0 4.0"
        };
    }
	var facilities = lgaData.facilities;
	var sectors = variableData.sectors;
	var sector = Sectors.pluck(params.sector)
	var e = {
	    state: state.slug,
        lga: lga.slug,
        mode: 'facilities',
	    sector: sector,
	    subsector: sector.getSubsector(params.subsector),
	    indicator: sector.getIndicator(params.indicator)
	};
	NMIS.loadFacilities(facilities);
	if(e.sector !== undefined && e.subsector === undefined) {
	    e.subsector = _.first(e.sector.subGroups());
	}

    var MapMgr_opts = {
        llString: lgaData.profileData.gps.value,
        elem: wElems.elem0
    };
	if(!MapMgr.init(MapMgr_opts)) {
	    MapMgr.addLoadCallback(function(){
            var map = new google.maps.Map(this.elem.get(0), {
                zoom: 8,
                center: new google.maps.LatLng(this.ll.lat, this.ll.lng),
                streetViewControl: false,
                panControl: false,
                zoomControlOptions: {
                    position: new google.maps.ControlPosition()
                },
                mapTypeControlOptions: {
                    mapTypeIds: ["roadmap", "satellite", "terrain", "OSM"]
                },
                mapTypeId: google.maps.MapTypeId[this.defaultMapType]
            });
            // OSM google maps layer code from:
            // http://wiki.openstreetmap.org/wiki/Google_Maps_Example#Example_Using_Google_Maps_API_V3
            map.mapTypes.set("OSM", new google.maps.ImageMapType({
                getTileUrl: function(coord, zoom) {
                    return "http://tile.openstreetmap.org/" + zoom + "/" + coord.x + "/" + coord.y + ".png";
                },
                tileSize: new google.maps.Size(256, 256),
                name: "OpenStreetMap",
                maxZoom: 18
            }));

            this.map = map;
            var bounds = new google.maps.LatLngBounds();
            NMIS.IconSwitcher.setCallback('createMapItem', function(item, id, itemList){
                if(!!item._ll) {
                    var iconData = (function iconDataForItem(i){
                        var iconSlug = i.iconType || i.sector.slug;
                        var iconFiles = {
                            education: "school_w.png",
                            health: "clinic_s.png",
                            water: "water_small.png",
                            default: "book_green_wb.png"
                        };
                        var iconId = iconFiles[iconSlug] || iconFiles['default'];
                        return {
                            width: 34,
                            height: 20,
                            url: "/static/images/icons/" + iconId
                        }
                    })(item);

                    var latlng = new google.maps.LatLng(item._ll[0], item._ll[1]),
                        marker = new google.maps.Marker({
                        position: latlng,
                        map: map,
                        icon: new google.maps.MarkerImage(
                            // url
                            iconData.url,
                            // size
                            new google.maps.Size(iconData.width, iconData.height)//,
                            // origin
//                            new google.maps.Point(10, 10)
                            // anchor
//                            new google.maps.Point(5, 5)
                            )
                    });
                    bounds.extend(latlng);
                }
            });
            NMIS.IconSwitcher.createAll();
            map.fitBounds(bounds);
	    });
	}

	if(e.sector.slug==='overview') {
	    wElems.elem1content.empty();
	    NMIS.DisplayWindow.setTempSize("minimized", true);
        var displayTitle = "Facility Detail: "+lga.name+" Overview";
        NMIS.DisplayWindow.setTitle(displayTitle);
        NMIS.IconSwitcher.shiftStatus(function(id, item) {
            return "normal";
        });
    } else {
        NMIS.IconSwitcher.shiftStatus(function(id, item) {
            return item.sector === e.sector ? "normal" : "inactive";
        });
        var displayTitle = "Facility Detail: "+lga.name+" " + e.sector.name;
        NMIS.DisplayWindow.setTitle(displayTitle);
        NMIS.DisplayWindow.unsetTempSize(true);
        var tableElem = FacilityTables.createForSectors([e.sector.slug], {
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
            },
            indicatorClickCallback: function() {
                if(!!this.clickable) {
                    var clickUrl = NMIS.urlFor(_.extend({}, e, {
                        indicator: this.slug
                    }));
                    dashboard.setLocation(clickUrl);
                }
            }
        });
        tableElem.find('tbody').delegate('tr', 'click', function(){
            FacilitySelector({id: $(this).data('facilityId')});
        });
        tableElem.appendTo(wElems.elem1content);
        if(!!e.subsector) FacilityTables.select(e.sector, e.subsector);
        if(!!e.indicator) (function(){
            $('.indicator-feature').remove();
            var obj = {
                name: e.indicator.name
            };
            $(mustachify('indicator-feature', obj)).prependTo('.facility-display');
            FacilityTables.highlightColumn(e.indicator);
        })();
	}
}
function mustachify(id, obj) {
    return Mustache.to_html($('#'+id).eq(0).html().replace(/<{/g, '{{').replace(/\}>/g, '}}'), obj);
}