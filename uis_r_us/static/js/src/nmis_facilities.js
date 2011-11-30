//FacilitySelector will probably end up in the NMIS object like all the other modules.
var FacilitySelector = (function(){
    var active = false;
    function activate(params){
        var fId = params.id;
        NMIS.IconSwitcher.shiftStatus(function(id, item) {
            if(id !== fId) {
                return "background";
            } else {
                active = true;
                return "normal";
            }
        });
    }
    function isActive(){
        return active;
    }
    function deselect() {
        if(active) {
            var sector = NMIS.activeSector();
            NMIS.IconSwitcher.shiftStatus(function(id, item) {
                return item.sector === sector ? "normal" : "background";
            });
            active = false;
        }
    }
    return {
        activate: activate,
        isActive: isActive,
        deselect: deselect
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
	NMIS.activeSector(sector);
	NMIS.loadFacilities(facilities);
	if(e.sector !== undefined && e.subsector === undefined) {
	    e.subsector = _.first(e.sector.subGroups());
	    e.subsectorUndefined = true;
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
                name: "OSM",
                maxZoom: 18
            }));

            this.map = map;
            var bounds = new google.maps.LatLngBounds();
            function iconURL(slug, status) {
                var iconFiles = {
                    education: "education.png",
                    health: "health.png",
                    water: "water.png",
                    default: "book_green_wb.png"
                };
                var url = "/static/images/icons_f/" + status + "_" + (iconFiles[slug] || iconFiles['default']);
                return url
            }
            function iconURLData(slug, status) {
                return [iconURL(slug, status), 32, 24];
            }
            function markerClick(){
                var sslug = NMIS.activeSector().slug;
                if(sslug==this.nmis.item.sector.slug || sslug === "overview") {
                    FacilitySelector.activate({id: this.nmis.id});
                }
            }
            function mapClick() {
                if(FacilitySelector.isActive()) {
                    FacilitySelector.deselect();
                }
            }
            google.maps.event.addListener(map, 'click', mapClick);
            NMIS.IconSwitcher.setCallback('createMapItem', function(item, id, itemList){
                if(!!item._ll && !this.mapItem(id)) {
                    var $gm = google.maps;
                    var iconData = (function iconDataForItem(i){
                        i.iconSlug = i.iconType || i.sector.slug;
                        var td = iconURLData(i.iconSlug, i.status || "normal");
                        return {
                            url: td[0],
                            size: new $gm.Size(td[1], td[2])
                        };
                    })(item);
                    var mI = {
                        latlng: new $gm
                                    .LatLng(item._ll[0], item._ll[1]),
                        icon: new $gm
                                    .MarkerImage(iconData.url, iconData.size)
                    };
                    mI.marker = new $gm
                                    .Marker({
                                        position: mI.latlng,
                                        map: map,
                                        icon: mI.icon
                                    });
                    mI.marker.setZIndex(item.status === "normal" ? 99: 11);
                    mI.marker.nmis = {
                        item: item,
                        id: id
                    };
                    google.maps.event.addListener(mI.marker, 'click', markerClick)
                    bounds.extend(mI.latlng);
                    this.mapItem(id, mI);
                }
            });
            NMIS.IconSwitcher.createAll();
            map.fitBounds(bounds);
            NMIS.IconSwitcher.setCallback('shiftMapItemStatus', function(item, id){
                var mapItem = this.mapItem(id);
                var icon = mapItem.marker.getIcon();
                icon.url = iconURL(item.sector.slug, item.status);
                mapItem.marker.setIcon(icon);
            });
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
        if(!!e.subsectorUndefined || !FacilitySelector.isActive()) {
            NMIS.IconSwitcher.shiftStatus(function(id, item) {
                return item.sector === e.sector ? "normal" : "background";
            });
        }
        var displayTitle = "Facility Detail: "+lga.name+" " + e.sector.name;
        if(!!e.subsector) {
            NMIS.DisplayWindow.setTitle(displayTitle, displayTitle + " - " + e.subsector.name);
        }
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
            FacilitySelector.activate({id: $(this).data('facilityId')});
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