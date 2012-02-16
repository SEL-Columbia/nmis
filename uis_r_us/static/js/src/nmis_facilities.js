var createOurGraph = (function(pieWrap, legend, data, _opts){
    //creates a graph with some default options.
    // if we want to customize stuff (ie. have behavior that changes based on
    // different input) then we should work it into the "_opts" parameter.
    var gid = $(pieWrap).get(0).id;
    if(!gid) {$(pieWrap).attr('id', 'pie-wrap'); gid = 'pie-wrap'; }
    var defaultOpts = {
        x: 50,
        y: 40,
        r: 35,
        font: "12px 'Fontin Sans', Fontin-Sans, sans-serif"
    };
    var opts = $.extend({}, defaultOpts, _opts);
    var rearranged_vals = $.map(legend, function(val){
        return $.extend(val, {
            value: data[val.key]
        });
    });
    var pvals = (function(vals){
        var values = [];
    	var colors = [];
    	var legend = [];
    	vals.sort(function(a, b){ return b.value - a.value; });
    	$(vals).each(function(){
    		if(this.value > 0) {
    			values.push(this.value);
    			colors.push(this.color);
    			legend.push('%% - ' + this.legend + ' (##)');
    		}
    	});
    	return {
    		values: values,
    		colors: colors,
    		legend: legend
    	}
    })(rearranged_vals);

    // NOTE: hack to get around a graphael bug!
    // if there is only one color the chart will
    // use the default value (Raphael.fn.g.colors[0])
    // here, we will set it to whatever the highest
    // value that we have is
    Raphael.fn.g.colors[0] = pvals.colors[0];
    var r = Raphael(gid);
    r.g.txtattr.font = opts.font;
    var pie = r.g.piechart(opts.x, opts.y, opts.r,
            pvals.values, {
                    colors: pvals.colors,
                    legend: pvals.legend,
                    legendpos: "east"
                });
    pie.hover(function () {
        this.sector.stop();
        this.sector.scale(1.1, 1.1, this.cx, this.cy);
        if (this.label) {
            this.label[0].stop();
            this.label[0].scale(1.4);
            this.label[1].attr({"font-weight": 800});
        }
    }, function () {
        this.sector.animate({scale: [1, 1, this.cx, this.cy]}, 500, "bounce");
        if (this.label) {
            this.label[0].animate({scale: 1}, 500, "bounce");
            this.label[1].attr({"font-weight": 400});
        }
    });
    return r;
});
// END raphael graph wrapper

//FacilitySelector will probably end up in the NMIS object like all the other modules.

+function facilitiesDisplay(){
    var lgaDataReq = NMIS.DataLoader.fetch("/facilities/site/" + lgaUniqueSlug);
	var variableDataReq = NMIS.DataLoader.fetch("/facility_variables");
    function loadFacilities() {
	    var params = {};
        if((""+window.location.search).match(/facility=(\d+)/)) {
            params.facilityId = (""+window.location.search).match(/facility=(\d+)/)[1];
        }
        $('#conditional-content').hide();
	    _.each(this.params, function(param, pname){
	        if($.type(param)==="string" && param !== '') {
	            params[pname] = param.replace('/', '');
	        }
	    });
        if(params.sector === 'overview') {
            params.sector = undefined;
        }
	    prepFacilities(params);
	    $.when(lgaDataReq, variableDataReq)
    		.done(function(req1, req2){
    		    var lgaData = req1[0];
                var variableData = req2[0];
                launchFacilities(lgaData, variableData, params);
    		});
	}
	dashboard.get("/nmis~/:state/:lga/facilities/?(#.*)?", loadFacilities);
	dashboard.get("/nmis~/:state/:lga/facilities/:sector/?(#.*)?", loadFacilities);
    dashboard.get("/nmis~/:state/:lga/facilities/:sector/:subsector/?(#.*)?", loadFacilities);
    dashboard.get("/nmis~/:state/:lga/facilities/:sector/:subsector/:indicator/?(#.*)?", loadFacilities);
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
    NMIS.DisplayWindow.setVisibility(true);
    var facilitiesMode = {name:"Facility Detail", slug:"facilities"};
	var e = {
	    state: state,
	    lga: lga,
	    mode: facilitiesMode,
	    sector: NMIS.Sectors.pluck(params.sector),
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

var facilitiesMapCreated;
function launchFacilities(lgaData, variableData, params) {
    if(lgaData.profileData===undefined) { lgaData.profileData = {}; }
    if(lgaData.profileData.gps === undefined) {
        lgaData.profileData.gps = {
            value: "40.809587 -73.953223 183.0 4.0"
        };
    }
	var facilities = lgaData.facilities;
	var sectors = variableData.sectors;
	var sector = NMIS.Sectors.pluck(params.sector)
	var e = {
	    state: state.slug,
        lga: lga.slug,
        mode: 'facilities',
	    sector: sector,
	    subsector: sector.getSubsector(params.subsector),
	    indicator: sector.getIndicator(params.indicator),
	    facilityId: params.facilityId
	};
	NMIS.Env(e);
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
    function createFacilitiesMap() {
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
        function iconURLData(item) {
            var slug, status = item.status;
            if(status==="custom") {
                return item._custom_png_data;
            }
            function sectorIconURL(slug, status) {
                var iconFiles = {
                    education: "education.png",
                    health: "health.png",
                    water: "water.png",
                    'default': "book_green_wb.png"
                };
                var url = "/static/images/icons_f/" + status + "_" + (iconFiles[slug] || iconFiles['default']);
                return url
            }
            slug = item.iconSlug || item.sector.slug;
            return [sectorIconURL(slug, status), 32, 24];
        }
        function markerClick(){
            var sslug = NMIS.activeSector().slug;
            if(sslug==this.nmis.item.sector.slug || sslug === "overview") {
                dashboard.setLocation(NMIS.urlFor(_.extend(NMIS.Env(), {
                    facilityId: this.nmis.id
                })));
            }
        }
        function markerMouseover() {
            var sslug = NMIS.activeSector().slug;
            if(this.nmis.item.sector.slug === sslug || sslug === "overview") {
                NMIS.FacilityHover.show(this);
            }
        }
        function markerMouseout() {
            NMIS.FacilityHover.hide();
        }
        function mapClick() {
            if(NMIS.FacilitySelector.isActive()) {
                NMIS.FacilitySelector.deselect();
                dashboard.setLocation(NMIS.urlFor(_.extend(NMIS.Env(), {
                    facilityId: false
                })));
            }
        }
        google.maps.event.addListener(map, 'click', mapClick);
        NMIS.IconSwitcher.setCallback('createMapItem', function(item, id, itemList){
            if(!!item._ll && !this.mapItem(id)) {
                var $gm = google.maps;
                var iconData = (function iconDataForItem(i){
                    i.iconSlug = i.iconType || i.sector.slug;
                    var td = iconURLData(i);
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
                google.maps.event.addListener(mI.marker, 'click', markerClick);
                google.maps.event.addListener(mI.marker, 'mouseover', markerMouseover);
                google.maps.event.addListener(mI.marker, 'mouseout', markerMouseout);
                bounds.extend(mI.latlng);
                this.mapItem(id, mI);
            }
        });
        NMIS.IconSwitcher.createAll();
        map.fitBounds(bounds);
        NMIS.IconSwitcher.setCallback('shiftMapItemStatus', function(item, id){
            var mapItem = this.mapItem(id);
            if(!!mapItem) {
                var icon = mapItem.marker.getIcon();
                icon.url = iconURLData(item)[0];
                mapItem.marker.setIcon(icon);
            }
        });
    }
    if(!facilitiesMapCreated) {
        if(NMIS.MapMgr.isLoaded()) {
            createFacilitiesMap()
        } else {
            NMIS.MapMgr.addLoadCallback(createFacilitiesMap);
            NMIS.MapMgr.init(MapMgr_opts);
        }
        facilitiesMapCreated = true;
    }
    NMIS.DisplayWindow.setDWHeight('calculate');
	if(e.sector.slug==='overview') {
	    wElems.elem1content.empty();
//	    NMIS.DisplayWindow.setTempSize("minimized", true);
        var displayTitle = "Facility Detail: "+lga.name+" Overview";
        NMIS.DisplayWindow.setTitle(displayTitle);
        NMIS.IconSwitcher.shiftStatus(function(id, item) {
            return "normal";
        });
    } else {
        if(!!e.subsectorUndefined || !NMIS.FacilitySelector.isActive()) {
            NMIS.IconSwitcher.shiftStatus(function(id, item) {
                return item.sector === e.sector ? "normal" : "background";
            });
        }
        var displayTitle = "Facility Detail: "+lga.name+" " + e.sector.name;
        if(!!e.subsector) {
            NMIS.DisplayWindow.setTitle(displayTitle, displayTitle + " - " + e.subsector.name);
        }
//        NMIS.DisplayWindow.unsetTempSize(true);
        wElems.elem1content.empty();
        var twrap = $('<div />', {'class':'facility-table-wrap'}).appendTo(wElems.elem1content);
        var tableElem = NMIS.SectorDataTable.createIn(twrap, e, {
            sScrollY: 146
        })
            .addClass('bs');
        NMIS.DisplayWindow.addCallback('resize', function(tf, size){
            var availH = $('.display-window-content').height()-154;
            if(size==="full") {
                NMIS.SectorDataTable.updateScrollSize(availH);
                wElems.wrap.css({'height':'auto'});
            } else if(size==="middle") {
                NMIS.SectorDataTable.updateScrollSize(availH);
            }
        });
        if(!!e.indicator) (function(){
            if(e.indicator.iconify_png_url) {
                NMIS.IconSwitcher.shiftStatus(function(id, item) {
                    if(item.sector === e.sector) {
                        item._custom_png_data = e.indicator.customIconForItem(item)
                        return "custom";
                    } else {
                        return "background";
                    }
                });
            }
            $('.indicator-feature').remove();
            var obj = _.extend({}, e.indicator);
            var mm = $(mustachify('indicator-feature', obj));
            mm.find('a.close').click(function(){
                var xx = NMIS.urlFor(_.extend({}, e, {indicator: false}));
                dashboard.setLocation(xx);
                return false;
            });
            mm.prependTo(wElems.elem1content);
            (function(pcWrap){
                var sector = e.sector,
                    column = e.indicator;
                var piechartTrue = _.include(column.click_actions, "piechart_true"),
                    piechartFalse = _.include(column.click_actions, "piechart_false"),
                    pieChartDisplayDefinitions;
                if(piechartTrue) {
                    pieChartDisplayDefinitions = [{'legend':'No', 'color':'#ff5555', 'key': 'false'},
                                                        {'legend':'Yes','color':'#21c406','key': 'true'},
                                                        {'legend':'Undefined','color':'#999','key': 'undefined'}];
                } else if(piechartFalse) {
                    pieChartDisplayDefinitions = [{'legend':'Yes', 'color':'#ff5555', 'key': 'true'},
                                                        {'legend':'No','color':'#21c406','key': 'false'},
                                                        {'legend':'Undefined','color':'#999','key': 'undefined'}];
                }
                if(!!pieChartDisplayDefinitions) {
                    var tabulations = NMIS.Tabulation.sectorSlug(sector.slug, column.slug, 'true false undefined'.split(' '));
                    createOurGraph(pcWrap, pieChartDisplayDefinitions, tabulations, {});
                }
            })(mm.find('.raph-circle').get(0));
        })();
	}
	if(!!e.facilityId) {
	    NMIS.FacilitySelector.activate({
	        id: e.facilityId
	    });
	}
}
function mustachify(id, obj) {
    return Mustache.to_html($('#'+id).eq(0).html().replace(/<{/g, '{{').replace(/\}>/g, '}}'), obj);
}