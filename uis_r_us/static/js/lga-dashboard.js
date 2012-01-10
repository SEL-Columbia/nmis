;
// BEGIN raphael graph wrapper
var createOurGraph = (function(pieWrap, legend, data, _opts){
    //creates a graph with some default options.
    // if we want to customize stuff (ie. have behavior that changes based on
    // different input) then we should work it into the "_opts" parameter.
    var gid = $(pieWrap).get(0).id;
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

function SummaryText(t){
    var sp = $('#lga-widget-wrap').find('.summary-p');
    if(sp.length===0) {
        sp = $('<div />')
                .addClass('summary-p')
                .appendTo('#lga-widget-wrap');
    }
    t !== undefined && sp.html(t);
    return sp;
}

var HandleIcons = (function(){
    // I'm starting to move away from olStyling handling all the icon changes.
    window.zActions = [];

    window.createIcon = function(f, info){
        var url = info.url;
        var size = info.size;
        f.mrkr === undefined && (function(){
            var s = new OpenLayers.Size(size[0], size[1])
            var offset = new OpenLayers.Pixel(-(s.w/2), -s.h);
            f._defaultIconUrl = url;
            var icon = new OpenLayers.Icon(url, s, offset);
            f.openLayersLatLng = new OpenLayers.LonLat(f.latlng[1], f.latlng[0])
                .transform(new OpenLayers.Projection("EPSG:4326"), new OpenLayers.Projection("EPSG:900913"));
            f.mrkr = new OpenLayers.Marker(f.openLayersLatLng, icon);
            f.mrkr.events.register('click', f.mrkr, function(){
                setFacility(f.uid);
            });
        })();
        return f.mrkr;
    }

    function showHideFacility(f, bool) {
        var m = f.mrkr;
        !!bool && m !== undefined && $(m.icon.imageDiv).show();
        !bool && m !== undefined && $(m.icon.imageDiv).hide();
    }

    function changeIcon(f, columnVariable, iconUrl){
        var icon = '' + iconUrl + f[columnVariable] + '.png';
        zActions.push("icon:"+icon);
        f.mrkr !== undefined && f.mrkr.icon.setUrl(icon);
    }

    function resetIcon(f){
        f.mrkr !== undefined && f._defaultIconUrl !== undefined &&
            f.mrkr.icon.setUrl(f._defaultIconUrl);
        zActions.push("reset:"+f._id);
    }

    return function(facilityData, opts){
        zActions = [];
        // opts.filterSector is passed to "HandleIcons"
        var s = opts.filterSector;
        //__sector is the [temp] global sector reference
        //  ...I don't want to count on in permanently, if possible
        var _s = __sector;
        var actions = {
            sector: opts.filterSector !== undefined,
            unfilter: !!opts.unfilter,
            changeIcon: opts.iconColumn !== undefined,
            showFacility: opts.showFacility !== undefined,
            resetIcons: !!opts.resetIcons
        };
        var c = 0;
        var _c = 0;
        $.each(facilityData.list, function(id, f){
            if(s==='overview' || actions.unfilter) {
                actions.sector && showHideFacility(f, true);
            } else {
                actions.sector && showHideFacility(f, f.sector === s);
            }
            actions.changeIcon && changeIcon(f, opts.iconColumn, opts.iconifyUrl);
            actions.resetIcons && resetIcon(f);
            actions.showFacility && showHideFacility(f, opts.showFacility===f._id);
        });
        log("icons will ", JSON.stringify(opts));
    }
})();

(function forDebuggingOnly(){
    var _onChangeIconsShould = [];
    function iconsShould(str, onleaveShould){
        iconsShouldReset();
        if(onleaveShould !== undefined) {onLeaveIconsShould(onleaveShould);}
    //    log("Icons should "+str);
    }
    function iconsShouldReset(){
        $(_onChangeIconsShould).each(function(i, fn){fn.call()});
        _onChangeIconsShould = [];
    }
    function onLeaveIconsShould(str) {
    //    _onChangeIconsShould.push(function(){log(" ..." + str)})
    }

    window.iconsShould = iconsShould;
    window.iconsShouldReset = iconsShouldReset;
})();

// BEGIN CLOSURE: LGA object
//   --wraps everything to keep it out of the global scope.
var lga = (function(){

// BEGIN closure scope variable declaration
//   --marking which variables are going to be reused between functions
var selectedSubSector,
    selectedSector,
    selectedFacility,
    selectedColumn,
    facilitySectorSlugs,
    facilityData,
    dataDictionary,
    overviewVariables,
    facilitySectors;

var facilityTabsSelector = 'div.lga-widget-content';

var specialClasses = {
    showTd: 'show-me',
    tableHideTd: 'hide-tds'
};
var urls = {
    variables: '/facility_variables',
    lgaSpecific: '/facilities/site/'
};

var subSectorDelimiter = '-';
var defaultSubSector = 'general';
// END closure scope variable declaration

// BEGIN icon handling within the closure scope
(function(){
    var _onChangeIconsWill = [];

    function iconsWill(command, onLeaveCommand) {
        iconsWillReset()
        if(onLeaveCommand!==undefined) { onLeaveIconsWill(onLeaveCommand); }
        var o = command;

        if(typeof(command)==="function") { o = command(); }
        HandleIcons(facilityData, o);
//        log("icons will ", JSON.stringify(o));
    }

    function onLeaveIconsWill(command){
        _onChangeIconsWill.push(function(){
            var o = command;
            if(typeof(command)==="function") { o = command(); }
            HandleIcons(facilityData, o);
//            log(" .....", JSON.stringify(o));
        });
    }

    function iconsWillReset(){
        $(_onChangeIconsWill).each(function(i, fn){fn.call()});
        _onChangeIconsWill = [];
    }

    window.onLeaveIconsWill = onLeaveIconsWill;
    window.iconsWill = iconsWill;
    window.iconsWillReset = iconsWillReset;
})();
// END icon handling within the closure scope

// BEGIN load lga data via ajax
function loadLgaData(lgaUniqueId, onLoadCallback) {
    var siteDataUrl = urls.lgaSpecific + lgaUniqueId;
    var variablesUrl = urls.variables;
	var fv1 = $.getCacheJSON(siteDataUrl);
	var fvDefs = $.getCacheJSON(variablesUrl);
	var fvDict = $.getCacheJSON("/static/json/variable_dictionary.json");
    var dataDict = $.getCacheJSON("/facilities/data_dictionary");
	$.when(fv1, fvDefs, fvDict, dataDict).then(function(lgaQ, varQ, varDict, dDict){
	    var variableDictionary = varDict[0];
	    var lgaData = lgaQ[0];
		var stateName = lgaData.stateName;
		var lgaName = lgaData.lgaName;
		if(!!lgaData.error) {
		    return $('<p />')
		        .attr('title', 'Error')
		        .text(lgaData.error)
		        .appendTo($('#map'))
		        .dialog();
		}
		var facilityData = lgaData.facilities;
        dataDictionary = dDict[0];
		var varDataReq = varQ[0];
		var facilityDataARr = [];
		$.each(facilityData, function(k, v){
			v.uid = k;
			facilityDataARr.push(v);
		});

		(function(){
		    $('.replace-data').each(function(){
		        var result = lgaData.profileData[$(this).data().lgaVariable];
		        if(!!result) {
    		        $(this).text(result.value || "&nbsp;");
		        }
        	});
        	$('.replace-counts').each(function(){
        	    var countSlug = $(this).data('countSlug');
        	    if(countSlug==="facilities") {
        	        $(this).text('('+ facilityDataARr.length + ')')
        	    } else if(countSlug.indexOf('sector:')!==-1) {
        	        var sectorSlug = countSlug.replace('sector:', '');
        	    }
        	});
		})();
//        buildLgaProfileBox(lgaData, profile_variables);
		processFacilityDataRequests(lgaQ, {
		    sectors: varDataReq.sectors,
		    overview: varDataReq.overview,
		    data: facilityDataARr
		});
		if(facilityData!==undefined && facilitySectors!==undefined) {
			var context = {
				data: facilityData,
				sectors: facilitySectors,
				stateName: stateName,
				lgaName: lgaName,
				triggers: [],
				trigger: function addTrigger(tname, edata) {
				    this.triggers.push([tname, edata || {}]);
				},
				buildTable: false
			};
		    !FACILITY_TABLE_BUILT && buildFacilityTable(
		                $('#lga-widget-wrap'),
		                facilityData, facilitySectors, lgaData);
			onLoadCallback.call(context);
			if(context.triggers.length===0) {
			    //set up default page mode
//			    setSector(defaultSectorSlug);
//			    $('body').trigger('select-sector', {
//            	        fullSectorId: defaultSectorSlug,
//            	        viewLevel: 'facility'
//            	        });
			} else {
			    $.each(context.triggers, function(i, tdata){
    			    $('body').trigger(tdata[0], tdata[1]);
    			});
			}
		}
	}, function dataLoadFail(){
		log("Data failed to load");
	});
};
(function($){
    //a quick ajax cache, merely trying to prevent multiple
    // requests to the same url in one pageload... (for now)
    var cacheData = {};
    $.getCacheJSON = function(){
        var url = arguments[0];
        if(url in cacheData) {
            return cacheData[url];
        } else {
            var q = $.getJSON.apply($, arguments);
            q.done(function(){
                cacheData[url] = q;
            });
            return q;
        }
    }
})(jQuery);
// END load lga data via ajax

// BEGIN lga-wide profile boxes
function getBoxOrCreateDiv(container, selector, creator) {
    var d = $(container).find(selector)
    if(d.length===0) {
        d = $.apply($, creator)
                .appendTo(container);
    }
    return d
}

window.hideProfileBox = function() {
    $('.profile-data-wrap').addClass('hidden');
    $('.profile-toggle').removeClass('active-button');
}

function buildLgaProfileBox(lga, dictionary) {
    var oWrap = getBoxOrCreateDiv('.content-inner-wrap', '.profile-data-wrap', ['<div />', {'class':'profile-data-wrap'}])
    var wrap = $("<div />", {'class':'profile-data'})
        .append($("<h3 />").text(lga.stateName))
        .append($("<h2 />").text(lga.lgaName))
        .append($("<hr />"));

	$('.map-key-w').find('.profile-toggle').addClass('active-button');

    $("<table />").append((function(tbody, pdata){
        $.each(dictionary, function(k, val){
            var name = val.name;
            var value = displayValue2(k, pdata[k]);
            var tr = $("<tr />")
                .append($("<td />").text(name))
                .append($("<td />").text(value));
            tbody.append(tr);
        });
        return tbody;
    })($('<tbody />'), lga.profileData))
        .appendTo(wrap);
    oWrap.html(wrap);
}

// END lga-wide profile boxes

// BEGIN page mode setters.
//  --ie. a bunch of methods to set various page states.
//    eg. setSector setViewMode setFacility setColumn
(function(){
    var nav;
    window.getNav = function(){
        if(nav===undefined || nav.length===0) { nav = $('.map-key-w'); }
        return nav;
    }
})();
function getColDataDiv() {
	var colData,
	    colDataWrap = $('.widget-outer-wrap').find('div.column-data-wrap');
	if(colDataWrap.length===0) {
		colDataWrap = $("<div />", {'class': 'column-data-wrap'})
		    .attr('style', 'display:block;position:absolute;bottom:255px;left:0;');
		$('<a />', {'href': '#', 'class': 'close-col-data'})
		    .css({'left':"993px"})
		    .text('X')
		    .click(function(){
		        iconsShouldReset();
		        iconsWillReset();
		        colDataWrap.hide();
		    })
		    .appendTo(colDataWrap);
		colData = $('<div />', {'class': 'column-data'})
		    .appendTo(colDataWrap);
		$('.widget-outer-wrap').prepend(colDataWrap);
	} else {
	    colData = colDataWrap.find('.column-data');
	}
	colDataWrap.show();
	return colData;
}

function ensureValidSectorLevel(level, sector) {
    if(level===undefined || sector === undefined) {
        return false;
    }
}

(function(){
    // BEGIN SETTER: sector
    var sectors = 'overview health education water'.split(' ');
    var _sector, _prevSector,
        _fullSectorId, _prevFullSectorId;
    window._sectorOnLeave = null;
    //right now, some things need access to the current sector slug,
    //  but I'm not sure if/how to expose it to the global scope yet.
    window.__sector = null;

    function subSectorExists(){return true;/*-- TODO: fix this --*/}

    window.setSector = function(s, ss){
        var curSectorObj = $(facilitySectors).filter(function(){return this.slug==s}).get(0);
        var fsid,
            stabWrap,
            changeSector = false
            changeSubSector = false;

        ensureValidSectorLevel(__viewMode, s);
        if(~sectors.indexOf(s)) { if(_sector !== s) {_prevSector = _sector; __sector = _sector = s; changeSector = true;} } else { warn("sector doesn't exist", s); }
        if(changeSector) {
            $.cookie('sector', s);
            // if a "leave" function is defined, it is executed and removed
            if(typeof _sectorOnLeave ==='function') {_sectorOnLeave(); _sectorOnLeave = null;}
            $('ul.nav')
                .find('.sector')
                .each(function(){
                    var $this = $(this);
                    if($this.data('sector')===s) {
                        $this.addClass('active');
                    } else {
                        $this.removeClass('active');
                    }
                });

            var nav = getNav();
            nav.find('.active-button.sector-button').removeClass('active-button');
            nav.find('.sector-'+s).addClass('active-button');

            //remove all TD filtering classes
            var ftabs = $(facilityTabsSelector);
            ftabs.find('.'+specialClasses.showTd).removeClass(specialClasses.showTd);
            ftabs.removeClass(specialClasses.tableHideTd);

            ftabs.find('.modeswitch').addClass('fl-hidden-sector')
                    .filter(function(){
                        if($(this).data('sectorSlug')===_sector) { return true; }
//                        if(this.id == "facilities-"+_sector) { return true; }
                    }).removeClass('fl-hidden-sector');
		    (typeof(filterPointsBySector)==='function') && filterPointsBySector(_sector);
        }

        if(curSectorObj===undefined) { return; }
        if(curSectorObj.subgroups===undefined) { return; }
        if(!curSectorObj.subgroups.length===0) { return; }
        if(ss===undefined) {
            ss = curSectorObj.subgroups[0].slug;
        }

        fsid = s + ':' + ss;
        if(subSectorExists(fsid)) { if(_fullSectorId !== fsid) { _prevFullSectorId = _fullSectorId; _fullSectorId = fsid; changeSubSector = true; }}
        if(changeSubSector) {
            var ftabs = $(facilityTabsSelector);

            (function markSubsectorLinkSelected(stabWrap){
                var ssList = stabWrap.find('.sub-sector-list');
                ssList.find('.selected')
                    .removeClass('selected');
                ssList.find('.subsector-link-'+ss)
                    .addClass('selected');
            })(ftabs.find('.mode-facility.sector-'+s))
            ftabs.find('.'+specialClasses.showTd).removeClass(specialClasses.showTd)
            ftabs.find('.row-num, .subgroup-'+ss)
                .addClass(specialClasses.showTd);
            ftabs.addClass(specialClasses.tableHideTd);
//            var nav = getNav();
//            nav.find('.sector-notes').text('subsector: '+ss);
        }
        return changeSubSector;
    }
    // END SETTER: sector
})();

(function(){
    // BEGIN SETTER: viewMode
    var viewModes = 'facility lga'.split(' ');
    var _viewMode, _prevViewMode;

    window.__viewMode = null;
    window.setViewMode = function SetViewMode(s){
        var change = false;
        if(ensureValidSectorLevel(s, __sector)) { return; }
        if(~viewModes.indexOf(s)) { if(_viewMode !== s) {_prevViewMode = _viewMode; __viewMode = _viewMode = s; change = true;} } else { warn("viewMode doesn't exist", s); }
        if(change) {
            $.cookie('level', s);
            var nav = getNav();
            nav.find('.active-button.view-mode-button').removeClass('active-button');
            nav.find('.view-mode-'+s).addClass('active-button');

            var ftabs = $(facilityTabsSelector);
            ftabs.find('.modeswitch').addClass('fl-hidden-view-mode');
            ftabs.find('.modeswitch.mode-'+_viewMode).removeClass('fl-hidden-view-mode');
            if(_viewMode==="lga") {
                ftabs.height(460);
            } else {
                ftabs.height(220);
            }
        }
        return change;
    }
    // END SETTER: viewMode
})();

function imageUrls(imageSizes, imgId) {
    return {
        small: ["/survey_photos", imageSizes.small, imgId].join("/"),
        large: ["/survey_photos", imageSizes.large, imgId].join("/"),
        original: ["/survey_photos", 'original', imgId].join("/")
    }
}

(function(){
    // BEGIN SETTER: facility
    var _facility, _previousFacility;

    window.setFacility = function(fId){
        var facility = facilityData.list[fId];
        if(facility!==undefined) {
            facility.tr === undefined || $(facility.tr).addClass('selected-facility');
        	var popup = $("<div />");
        	var sector = $(facilitySectors).filter(function(){return this.slug==facility.sector}).get(0);
        	var name = facility.name || facility.facility_name || facility.school_name;
            getMustacheTemplate('facility_popup', function(){
                var data = {sector_data: []};
                data.name = name || sector.name + ' Facility';
        		data.image_url = "http://nmis.mvpafrica.org/site-media/attachments/" +
        		        (facility.photo || "image_not_found.jpg");
        		var subgroups = {};
        		$(sector.columns).each(function(i, col){
        		    $(col.subgroups).each(function(i, val){
        		        if(val!=="") {
        		            if(!subgroups[val]) { subgroups[val] = []; }
            		        subgroups[val].push({
            		            name: col.name,
            		            slug: col.slug,
            		            value: displayValue2(col.slug, facility[col.slug])
            		        });
        		        }
        		    });
        		});
        		$(sector.subgroups).each(function(i, val){
                    subgroups[this.slug] !== undefined &&
        		        data.sector_data.push($.extend({}, val, { variables: subgroups[this.slug] }));
        		});
        		var pdiv = $(Mustache.to_html(this.template, data));
        		pdiv.delegate('select', 'change', function(){
        		    var selectedSector = $(this).val();
        		    pdiv.find('div.facility-sector-select-box')
        		        .removeClass('selected')
        		        .filter(function(){
            		        if($(this).data('sectorSlug')===selectedSector) {
            		            return true;
            		        }
            		    })
            		    .addClass('selected');
        		});
        		pdiv.find('select').trigger('change');
                popup.append(pdiv);
                popup.attr('title', name);
                var pdWidth = 600;
                var pdRight = ($(window).width() - pdWidth) / 2;
                popup.dialog({
                    width: pdWidth,
                    resizable: false,
                    position: [pdRight, 106],
                    close: function(){
                        setFacility();
                        iconsShouldReset();
                        iconsWillReset();
                    }
                });
            });
        	/*-
        	TODO: reimplement "scrollTo"
        	edata.scrollToRow && false && (function scrollToTheFacilitysTr(){
        		if(facility.tr!==undefined) {
        			var ourTr = $(facility.tr);
        			var offsetTop = ourTr.offset().top - ourTr.parents('table').eq(0).offset().top
        			var tabPanel = ourTr.parents('.ui-tabs-panel');
        			tabPanel.scrollTo(offsetTop, 500, {
        				axis: 'y'
        			});
        		}
        	})();
        	-*/
            // $.each(facilityData.list, function(i, fdp){
            //     olStyling.markIcon(fdp, facility===fdp ? 'showing' : 'hidden');
            // });
        	iconsShould("show selected facility, fade all the others", "unselect the facility");

        	iconsWill(function showFacility(){
        	    return {
//        	        filterSector: facility.sector,
        	        showFacility: facility._id
        	    };
        	}, function(){
        	    return {
        	        filterSector: __sector,
            	    unShowFacility: facility._id
            	}
        	});
        } else {
            //unselect facility
            //             $.each(facilityData.list, function(i, fdp){
            //                 if(selectedSector=="all" || fdp.sectorSlug === __sector) {
            //                     olStyling.markIcon(fdp, 'showing');
            //                 } else {
            //                     olStyling.markIcon(fdp, 'hidden');
            //                 }
            // });
            $('tr.selected-facility').removeClass('selected-facility');
        }
    }
    // END SETTER: facility
})();

//** getTabulations has been replaced by the testable "Tabulations" module.
// function getTabulations(sector, col, keysArray) {
//  var sList = facilityData.bySector[sector];
//  var valueCounts = {};
//  // if we specify a "keysArray", then the returned valueCounts will include zero values
//  // for those keys.
//  if(keysArray!==undefined) { $.each(keysArray, function(i, val){valueCounts[val]=0;}) }
//  $(sList).each(function(i, id){
//      var fac = facilityData.list[id];
//      var val = fac[col];
//      if(val === undefined) {val = 'undefined'}
//      if(valueCounts[val] === undefined) { valueCounts[val] = 0; }
//      valueCounts[val]++;
//  });
//  return valueCounts;
// }

(function(){
    var _selectedColumn;

    window.unsetColumn = function(){
        $('.selected-column').removeClass('selected-column');
        selectedColumn = undefined;
    	getColDataDiv().empty().css({'height':0});
    }
    window.setColumn = function(sector, column){
        var wrapElement = $('#lga-widget-wrap');
        if(_selectedColumn !== column) {
    		if(column.clickable) {
    			$('.selected-column', wrapElement).removeClass('selected-column');
    			(function highlightTheColumn(column){
    				var columnIndex = column.thIndex;
    				var table = column.th.parents('table');
    				column.th.addClass('selected-column');
    				table.find('tr').each(function(){
    					$(this).find('td').eq(columnIndex).addClass('selected-column');
    				})
    			})(column);
    		}
    		function hasClickAction(col, str) {
    		    return col.click_actions !== undefined && ~column.click_actions.indexOf(str);
    		}
    		var hasPieChart = hasClickAction(column, 'piechart_true') || hasClickAction(column, 'piechart_false');
        	if(hasClickAction(column, 'tabulate') || hasPieChart) {
                // var tabulations = $.map(getTabulations(sector.slug, column.slug), function(k, val){
                //                     return { 'value': k, 'occurrences': val }
                //                 });
                var tabulations = NMIS.Tabulation.sectorSlugAsArray(sector.slug, column.slug);
                getMustacheTemplate('facility_column_description', function(){
                    var data = {
                        tabulations: tabulations,
                        sectorName: sector.name,
                        name: column.name,
                        descriptive_name: column.descriptive_name,
                        description: column.description
                    };
                    var cdd = getColDataDiv()
                            .html(Mustache.to_html(this.template, data))
                            .css({
                                height: 180,
                                width: 1000
                                });
                    if(hasClickAction(column, 'piechart_true') || hasClickAction(column, 'piechart_false')) {
                        var pcWrap = cdd.find('.content').eq(0)
            		        .attr('id', 'pie-chart')
			        .show()
            		        .empty();
                        if(hasClickAction(column, 'piechart_true')) {
                            var pieChartDisplayDefinitions = [
                                {'legend':'No', 'color':'#ff5555', 'key': 'false'},
                                {'legend':'Yes','color':'#21c406','key': 'true'},
                                {'legend':'Undefined','color':'#999','key': 'undefined'}];
                        }
                        else if(hasClickAction(column, 'piechart_false')) {
                            var pieChartDisplayDefinitions = [
                                {'legend':'Yes', 'color':'#ff5555', 'key': 'true'},
                                {'legend':'No','color':'#21c406','key': 'false'},
                                {'legend':'Undefined','color':'#999','key': 'undefined'}];
                        } else {
			    pcWrap.find('.content').hide();
			}
//                        var tabulations = getTabulations(sector.slug, column.slug, 'true false undefined'.split(' '));
                        var tabulations = NMIS.Tabulation.sectorSlug(sector.slug, column.slug, 'true false undefined'.split(' '));
            		    createOurGraph(pcWrap,
            		                    pieChartDisplayDefinitions,
            		                    tabulations,
            		                    {});

                        var cdiv = $("<div />", {'class':'col-info'}).html($("<h2 />").text(column.name));
            			if(column.description!==undefined) {
            				cdiv.append($("<h3 />", {'class':'description'}).text(column.description));
            			}
                    } else {
			cdd.find('.content').eq(0).hide();
		    }
                });
    		}
    		var columnMode = "view_column_"+column.slug;
    		if(hasClickAction(column, 'iconify') && column.iconify_png_url !== undefined) {
    		    var t=0, z=0;
    		    var iconStrings = [];
    		    iconsShould("change to reflect the iconify column", "undo the iconify stuff");

    		    iconsWill(function filterSector(){
    		        return {
    		            iconifyUrl: column.iconify_png_url,
    		            filterSector: sector.slug,
    		            iconColumn: column.slug
    		        }
    		    }, {
    		        filterSector: __sector,
                    resetIcons: true
    		    });

    		    $.each(facilityData.list, function(i, fdp){
    		        if(fdp.sectorSlug===sector.slug) {
    		            var iconUrl = column.iconify_png_url + fdp[column.slug] + '.png';
                        // olStyling.addIcon(fdp, columnMode, {
                        //     url: iconUrl,
                        //     size: [34, 20]
                        // });
    		        }
            	});
                // olStyling.setMode(facilityData, columnMode);
    		}
    		_selectedColumn = column;
        }
    }
})();
// END page mode binders

// BEGIN facility table builder
//   -- facility table builder receives the facility data
//      and builds a table for each sector. The rows of the
//      table correspond to the facilities.
var filterPointsBySector;
var FACILITY_TABLE_BUILT = false;

function setSummaryHtml(html) {
    return $('.summary-p').html(html);
}

function findSector(sectorSlug){
    return $(facilitySectors).filter(function(i, _s){
        return _s.slug == sectorSlug
    }).get(0);
}

function buildFacilityTable(outerWrap, data, sectors, lgaData){
    function _buildOverview(){
        var div = $('<div />');
        getMustacheTemplate('lga_overview', function(){
            var sectors = [];
            var varsBySector = {};
            $.each(overviewVariables, function(i, variable){
                if(variable.sector!==undefined) {
                    if(varsBySector[variable.sector]==undefined) {varsBySector[variable.sector] = [];}
                    variable.value = displayValue2(variable.slug, lgaData.profileData[variable.slug]);
                    if(!!variable.in_overview) {
                        varsBySector[variable.sector].push(variable);
                    }
                }
            });
            $.each(varsBySector, function(sectorSlug, variables){
                var s = findSector(sectorSlug);
                sectors.push($.extend(s, {
                    variables: variables
                }));
            });
            var overviewTabs = Mustache.to_html(this.template, {
                sectors: sectors
            });
            div.append($(overviewTabs).tabs());
        });
        return div;
    }
    function _buildSectorOverview(s){
        var div = $('<div />');
        getMustacheTemplate('lga_sector_overview', function(){
            var sectorObj = findSector(s);
            var data = {
                variables: []
            };
            data.name = sectorObj.name;
            $.each(overviewVariables, function(i, variable){
                if(!variable.in_overview && !!variable.in_sector && variable.sector == s) {
                    data.variables.push({
                        name: variable.name,
                        value: displayValue2(variable.slug, lgaData.profileData[variable.slug])
                    });
                }
            });
            var overviewTabs = Mustache.to_html(this.template, data);
            div.append(overviewTabs);
        });
        return div;
    }

    filterPointsBySector = function(sector){
        if(sector==='overview') {
            iconsShould("unfilter all the points.");
            iconsWill({
                unfilter: true
            });
        } else {
            //On first load, the OpenLayers markers are not created.
            // this "showHide" function tells us when to hide the markers
            // on creation.
            // function showHideMarker(pt, tf) {
            //     pt.showMrkr = tf;
            //     olStyling.markIcon(pt, tf ? 'showing' : 'hidden')
            // }
            // $.each(facilityData.list, function(i, pt){
            //     showHideMarker(pt, (pt.sector === sector))
            // });
            iconsShould("filter the points down to sector:"+sector);
            iconsWill(function(){
                return {
                    filterSector: sector
                }
            });
        }
    }
	FACILITY_TABLE_BUILT = true;
	$('<div />', {'id': 'toggle-updown-bar'}).html($('<span />', {'class':'icon'}))
	    .appendTo(outerWrap)
	    .click(function(){ outerWrap.toggleClass('closed');
			       getColDataDiv().parents('div.column-data-wrap').css({'bottom': outerWrap.hasClass('closed') ? 20 : 255});
			     });
	var lgaContent = $('<div />')
	        .addClass('lga-widget-content')
	        .appendTo(outerWrap);
	var ftabs = lgaContent;
    var overviewDiv = $('<div />')
	    .addClass('modeswitch')
	    .addClass('mode-facility')
	    .addClass('sector-overview')
	    .data('sectorSlug', 'overview');

    var oc = $('.overview-content').html();
    $('.overview-content').remove();
    overviewDiv.html(oc);

	overviewDiv.appendTo(ftabs);

	$.each(facilitySectors, function(i, sector){
	    createTableForSectorWithData(sector, facilityData)
	        .addClass('modeswitch') //possibly redundant.
	        .appendTo(ftabs);

	    $('<div />')
	        .addClass('mode-lga')
	        .addClass('modeswitch')
	        .html(_buildSectorOverview(sector.slug))
	        .addClass('sector-'+sector.slug)
    	    .data('sectorSlug', sector.slug)
    	    .data('viewModeSlug', 'facility')
    	    .appendTo(ftabs);
	});
    // $('<div />')
    //     .addClass('modeswitch')
    //     .addClass('mode-facility')
    //     .addClass('sector-overview')
    //     .text('THIS IS THE OVERVIEW at the FACILITY LEVEL')
    //     .data('sectorSlug', 'overview')
    //     .data('viewModeSlug', 'facility')
    //     .appendTo(ftabs);
	$('<div />')
	    .addClass('modeswitch')
	    .addClass('mode-lga')
	    .addClass('sector-overview')
	    .html(_buildOverview())
	    .data('sectorSlug', 'overview')
	    .data('viewModeSlug', 'lga')
	    .appendTo(ftabs);
	ftabs.height(220);
	ftabs.find('.ui-tabs-panel').css({'overflow':'auto','height':'75%'});
	lgaContent.addClass('ready');
	loadMap && launchOpenLayers({
		centroid: {
			lat: 649256.11813719,
			lng: 738031.10112355
		},
		layers: [
		    ["Nigeria", "nigeria_base"]
		],
		overlays: [
		    ["Boundaries", "nigeria_overlays_white"]
		]
	})(function(){
	    function urlForSectorIcon(s) {
	        var surveyTypeColors = {
        		water: "water_small",
        		health: "clinic_s",
        		education: "school_w"
        	};
	        var st = surveyTypeColors[s] || surveyTypeColors['default'];
	        return '/static/images/icons/'+st+'.png';
	    }
		var iconMakers = {};
//		window._map = this.map;
		var markers = new OpenLayers.Layer.Markers("Markers");
		var bounds = new OpenLayers.Bounds();
		$.each(facilityData.list, function(i, d){
            if(d.latlng!==undefined) {
                d.sectorSlug = (d.sector || 'default').toLowerCase();
                var m = createIcon(d, {
                    url: urlForSectorIcon(d.sectorSlug),
                    size: [34, 20]
                });
                markers.addMarker(m);
                bounds.extend(m.lonlat);
            }
    	});
        // olStyling.setMarkerLayer(markers);
    	this.map.addLayer(markers);
        // olStyling.setMode(facilityData, 'main');
//		this.map.addLayers([tilesat, markers]);
    	this.map.zoomToExtent(bounds);
	});
}

var decimalCount = 1;
function displayValue(val) {
    if($.type(val)==='boolean') {
        return val ? 'Yes' : 'No';
    }
    return roundDownValueIfNumber(val);
}
function roundDownValueIfNumber(val) {
    if(val===undefined) { return 'n/a'; }
    if($.type(val)==='object') {val = val.value;}
    if($.type(val)==='number') {
        return Math.floor(Math.pow(10, decimalCount)* val)/Math.pow(10, decimalCount);
    } else if($.type(val)==='string') {
        return splitAndCapitalizeString(val);
//    } else if($.type(val)==='boolean') {
//        return val ? 'Yes' : 'No';
    }
    return val;
}
function capitalizeString(str) {
    var strstart = str.slice(0, 1);
    var strend = str.slice(1);
    return strstart.toUpperCase() + strend;
}
function splitAndCapitalizeString(str) {
    if (str == undefined) { return ""; }
    return $.map(str.split('_'), capitalizeString).join(' ');
}

function displayValue2(slug, value) {
    // interprets value as a dict if it has a value attribute
    if(value !== undefined && value.value !== undefined) { value = value.value; }
    if (dataDictionary[slug] == undefined) {
        return 'n/a';
    }
    switch (dataDictionary[slug]['data_type']) {
        case 'boolean':
            return value ? 'Yes' : 'No';
        case 'string':
            return splitAndCapitalizeString(value);
        case 'float':
            return roundDownValueIfNumber(value);
        case 'percent':
            return String(Math.round(roundDownValueIfNumber(value*100))) + '%';
        case 'proportion':
            return roundDownValueIfNumber(value);
        default:
            return 'n/a';
    }
}
function createTableForSectorWithData(sector, data){
    var sectorData = data.bySector[sector.slug] || data.bySector[sector.name];
	if(!sector.columns instanceof Array || !sectorData instanceof Array) {
	    return;
    }

    var thRow = $('<tr />')
                .append($('<th />', {
                    'text': '#',
                    'class': 'row-num no-select'
                }));
    function displayOrderSort(a,b) { return (a.display_order > b.display_order) ? 1 : -1 }
	$.each(sector.columns.sort(displayOrderSort), function(i, col){
	    var thClasses = ['col-'+col.slug, 'no-select'];
		col.clickable && thClasses.push('clickable');

		$(col.subgroups).each(function(i, sg){
			thClasses.push('subgroup-'+sg);
		});

		var th = $('<th />', {
		            'class': thClasses.join(' '),
		            'text': col.name
		        })
		        .click(function(){
//		            setSector(sector.slug);
// TODO: implement select column
		            setColumn(sector, col);
		        })
		        .appendTo(thRow);

		$.extend(col, { th: th, thIndex: i+1 });
	});

	var tbod = $("<tbody />");
	$.each(sectorData, function(i, fUid){
		tbod.append(createRowForFacilityWithColumns(data.list[fUid], sector.columns, i+1))
	});
	function defaultSubSector(sector) {
	    if(sector.subgroups instanceof Array
	            && sector.subgroups.length > 0) {
    	    return sector.subgroups[0].slug;
	    }
	    return 'general';
	}
	function subSectorLink(ssName, subSectorSlug) {
	    var fullSectorSlug = sector.slug + subSectorDelimiter + subSectorSlug;
	    return $('<a />', {'href': '#', 'class': 'subsector-link-'+subSectorSlug})
	                .text(ssName)
	                .click(function(evt){
	                    setSector(sector.slug, subSectorSlug);
	                    evt.preventDefault();
	                });
	}
	var subSectors = (function(subSectors, splitter){
	    $.each(sector.subgroups, function(i, sg){
	        i !== 0 && subSectors.append(splitter.clone());
	        subSectors.append(subSectorLink(sg.name, sg.slug));
    	});
    	return subSectors;
	})($('<div />', {'class': 'sub-sector-list no-select'}), $("<span />").text(" | "));

    var sectorTitle = $('<h2 />').text(sector.name);
    var table = $('<table />')
                    .addClass('facility-list')
                    .append($('<thead />').html(thRow))
                    .append(tbod);
    return $('<div />')
//	    .addClass('facility-list-wrap')
	    .addClass('modeswitch')
	    .addClass('mode-facility')
	    .addClass('sector-'+sector.slug)
	    .data('sectorSlug', sector.slug)
	    .append(sectorTitle)
	    .append(subSectors)
	    .append(table);
}

function createRowForFacilityWithColumns(fpoint, cols, rowNum){
    //creates a row for the facility table. (only used in "createTableForSectorWithData")
	var tr = $("<tr />")
	        .data('facility-uid', fpoint.uid)
	        .click(function(){
	            //clicking a row triggers global event 'select-facility'
	            setFacility(fpoint.uid);
	            $(this).trigger('select-facility', {
        		    'uid': fpoint.uid,
        		    'scrollToRow': false
        	    })
        	})
        	.append($('<td />', {'class':'row-num', 'text': rowNum}));

	$.each(cols, function(i, col){
		var value = roundDownValueIfNumber(fpoint[col.slug]);
		var td = $('<td />')
		        .addClass('col-'+col.slug)
		        .appendTo(tr);
		if(col.display_style == "checkmark_true" || col.display_style == "checkmark_false") {
			if($.type(value) === 'boolean') {
                if (col.display_style == "checkmark_true") {
			        td.addClass(!!value ? 'on-true' : 'off-true');
                }
                else if (col.display_style == "checkmark_false") {
			        td.addClass(!!value ? 'off-false' : 'on-false');
                }
			} else {
			    td.addClass('null');
			}
			td.addClass('checkmark')
			    .html($("<span />").addClass('mrk'));
		} else if(col.calc_action === "binarytally") {
		    //I think binarytally is no longer used.
			var cols = col.calc_columns.split(" ");
			var valx = (function calcRatio(pt, cols){
				var tot = 0;
				var num = 0;
				$(cols).each(function(i, slug){
					var val = pt[slug];
					num += ($.type(val) === 'boolean' && !!val) ? 1 : 0;
					tot += 1;
				});
				return [num, tot];
			})(fpoint, cols);

			td.data('decimalValue', valx[0]/valx[1]);
			td.append($("<span />", {'class':'numerator'}).text(valx[0]))
			    .append($("<span />", {'class':'div'}).text('/'))
			    .append($("<span />", {'class':'denominator'}).text(valx[1]));
		} else {
			td.text(value);
		}
		$(col.subgroups).each(function(i, sg){
			td.addClass('subgroup-'+sg);
		});
	});
	fpoint.tr = tr.get(0);
	return tr;
}
// END facility table builder

// BEGIN data processing:
//  -- data processing step receives the json data and 
//     processes it into the json format that is needed for the
//     page to function.
//     Note: in debug mode, it will give detailed descriptions of
//     the data is not in the correct format.
var processFacilityDataRequests = (function(dataReq, passedData){
    if(dataReq[2].processedData !== undefined) {
	    facilityData = dataReq[2].processedData.data;
	    facilitySectors = dataReq[2].processedData.sectors;
	    overviewVariables = dataReq[2].processedData.overview;
    } else {
		var data, sectors, noLatLngs=0;
		facilitySectorSlugs = [];
        NMIS.init(passedData.data, {
            iconSwitcher: false,
            sectors: passedData.sectors
        });

		passedData === undefined && warn("No data was passed to the page", passedData);

		debugMode && (function validateSectors(s){
		    // this is called if debugMode is true.
		    // it warns us if the inputs are wrong.
		    if(s===undefined || s.length == 0) {
		        warn("data must have 'sectors' list.")
		    }
		    var _facilitySectorSlugs = [];
			$(s).each(function(){
				this.name === undefined && warn("Each sector needs a name.", this);
				this.slug === undefined && warn("Each sector needs a slug.", this);
				this.columns instanceof Array || warn("Sector columns must be an array.", this);
				(this.slug in _facilitySectorSlugs) && warn("Slugs must not be used twice", this);
				_facilitySectorSlugs.push(this.slug);
				$(this.columns).each(function(i, val){
					var name = val.name;
					var slug = val.slug;
					name === undefined && warn("Each column needs a slug", this);
					slug === undefined && warn("Each column needs a name", this);
				});
			});
			sectors = s;
		})(passedData.sectors);

		sectors = [];
		facilitySectorSlugs = [];

		(function(s){
		    //processing passed sector data.
		    var slugs = [];
		    var _s = [];
		    $.each(s, function(i, ss){
		        if(!~slugs.indexOf(ss.slug)) { slugs.push(ss.slug); }
		        _s.push(ss);
		    });
		    facilitySectorSlugs = slugs;
		    sectors = _s;
		})(passedData.sectors);

		debugMode && (function validateData(d) {
		    d === undefined && warn('Data must be defined');
			d.length === undefined && warn("Data must be an array", this);
			$(d).each(function(i, row){
				this.sector === undefined && warn("Each row must have a sector", this);
				if(this.latlng === undefined) {
					//some points don't have latlngs but should show up in tables.
					noLatLngs++;
				} else {
					(this.latlng instanceof Array) || warn("LatLng must be an array", this);
					(this.latlng.length === 2) || warn("Latlng must have length of 2", this);
				}
				(!!~facilitySectorSlugs.indexOf(this.sector.toLowerCase())) || warn("Sector must be in the list of sector slugs:", {
					sector: this.sector,
					sectorSlugs: facilitySectorSlugs,
					row: this
				});
			});
		})(passedData.data);

		(function processData(rawData){
			function makeLatLng(val) {
				if(val !== undefined) {
					var lll = val.split(" ");
					return [
						+lll[0],
						+lll[1]
						]
				} else {
					return undefined
				}
			}
			var uidCounter = 0;
			var list = {};
			var groupedList = {};
			var sectorNames = [];
			$.each(sectors, function(i, s){
                if(!groupedList[s.slug]) {
                    groupedList[s.slug] = [];
                }
            });
			$.each(rawData, function(i, pt){
				if(pt.uid===undefined) { pt.uid = 'uid'+i; }
				pt.latlng = makeLatLng(pt.gps);
				pt.sector = pt.sector.toLowerCase();
				if(!~sectorNames.indexOf(pt.sector)) {
					sectorNames.push(pt.sector);
					groupedList[pt.sector] = [];
				}
				groupedList[pt.sector].push(pt.uid);
				list[pt.uid]=pt;
			});
			data = {
				bySector: groupedList, //sector-grouped list of IDs, for the time being
				list: list //the full list (this is actually an object where the keys are the unique IDs.)
			};
		})(passedData.data);
		debugMode && (function printTheDebugStats(){
			log("" + sectors.length + " sectors were loaded.");
			var placedPoints = 0;
			$(sectors).each(function(){
				if(data.bySector[this.slug] === undefined) {
					log("!->: No data loaded for "+this.name);
				} else {
					var ct = data.bySector[this.slug].length;
					placedPoints += ct;
					log("   : "+this.slug+" has "+ct+" items.", this);
				}
			});
			log(noLatLngs + " points had no coordinates")
		})();

		facilityData = data;
		window._facilityData = data;
		overviewVariables = passedData.overview;
    	facilitySectors = sectors;
    	//save it in the request object to avoid these checks
    	// in future requests...
    	//   (quick way to cache)
		dataReq[2].processedData = {
		    data: data,
		    sectors: sectors
		};
	}
});
// END data processing

return {
    loadData: loadLgaData
}
})();
// END CLOSURE: LGA object

if(typeof lgaId !== 'undefined') {
    var menu = $('<ul />', {id: 'menu'});
    $('#content').before(menu);
    var lgaTmpLink = $('<a />', {href:'/new_dashboard/'+lgaId, id:'lga-tmp-link'}).text('LGA')
    var facTmpLink = $('<a />', {href:'/~' + lgaId, id:'fac-tmp-link'}).text('Facilities');

    $('<li />').html(lgaTmpLink).appendTo(menu);
    $('<li />').html(facTmpLink).appendTo(menu);
}
