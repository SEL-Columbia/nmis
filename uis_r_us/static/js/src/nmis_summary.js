function activateGapAnalysis(){
    $('.gap-analysis').hide();
	$('.gap-analysis-activator').click(function(evt){
		var par = $(this).parents('.nmis-sector-summary').eq(0).toggleClass('view-gap');
		if(par.hasClass('view-gap')) {
			$('.non-gap', par).hide();
			$('.gap-analysis', par).show();
		} else {
			$('.gap-analysis', par).hide();
			$('.non-gap', par).show();
		}
		evt.preventDefault();
	});
}

(function summaryDisplay(){
    var summaryMap;
    function loadSummary(s){
        function initSummaryMap() {
            var $mapDiv = $('.profile-box .map').eq(0),
                mapDiv = $mapDiv.get(0),
                ll = _.map(lga.latLng.split(','), function(x){return +x}),
                mapZoom = 8;

            if(mapDiv) {
                if(!summaryMap) {
                    summaryMap = new google.maps.Map(mapDiv, {
                        zoom: mapZoom,
                        center: new google.maps.LatLng(ll[0], ll[1]),
                        streetViewControl: false,
                        panControl: false,
                        mapTypeControl: false,
                        mapTypeId: google.maps.MapTypeId.HYBRID
                    });
                    summaryMap.mapTypes.set('ng_base_map', NMIS.MapMgr.mapboxLayer({
            			tileset: 'nigeria_base',
            			name: 'Nigeria'
            		}));
            		summaryMap.setMapTypeId('ng_base_map');
                }
                _.delay(function(){
                    google.maps.event.trigger(summaryMap, 'resize');
                    summaryMap.setCenter(new google.maps.LatLng(ll[0], ll[1]), mapZoom);
                }, 1);
            }
        }
        if(NMIS.MapMgr.isLoaded()) {
            initSummaryMap();
        } else {
            NMIS.MapMgr.addLoadCallback(initSummaryMap);
            NMIS.MapMgr.init();
        }
        NMIS.DisplayWindow.setVisibility(false);
        NMIS.DisplayWindow.setDWHeight();
        var params = s.params;
        var _env = {
            mode: {name: 'Summary', slug: 'summary'},
            state: state,
            lga: lga,
            sector: NMIS.Sectors.pluck(params.sector) || overviewObj
        };
        var bcValues = prepBreadcrumbValues(_env,
                        "state lga mode sector subsector indicator".split(" "),
                        {state:state,lga:lga});
        NMIS.Breadcrumb.clear();
    	NMIS.Breadcrumb.setLevels(bcValues);
    	NMIS.LocalNav.markActive(["mode:summary", "sector:" + _env.sector.slug]);
        NMIS.LocalNav.iterate(function(sectionType, buttonName, a){
            var env = _.extend({}, _env);
            env[sectionType] = buttonName;
            a.attr('href', NMIS.urlFor(env));
        });
        (function displayConditionalContent(sector){
            var cc = $('#conditional-content').hide();
            cc.find('>div').hide();
            cc.find('>div.lga.'+sector.slug).show();
            cc.show();
        })(_env.sector);
    }
    dashboard.get("/nmis~/:state/:lga/summary/?(#.*)?", loadSummary);
    dashboard.get("/nmis~/:state/:lga/summary/:sector/?(#.*)?", loadSummary);
    dashboard.get("/nmis~/:state/:lga/summary/:sector/:subsector/?(#.*)?", loadSummary);
    dashboard.get("/nmis~/:state/:lga/summary/:sector/:subsector/:indicator/?(#.*)?", loadSummary);
})();
