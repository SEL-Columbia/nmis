(function(){
	NMIS = {};
	var template_cache = {};
	var views = {};

	$(function(){
		new Backbone.Router({
			routes: {
				'': index,
				':unique_lga': route(lga_overview),
				':unique_lga/health': route(lga_sector, 'health'),				
				':unique_lga/education': route(lga_sector, 'education'),
				':unique_lga/water': route(lga_sector, 'water'),
				':unique_lga/facility': route(facility_overview),
				//':unique_lga/facility_health': facility_health,
				//':unique_lga/facility_education': facility_education,	
				//':unique_lga/facility_water': facility_water
			}
		});
		Backbone.history.start();
	});
	

	// Page Views
	function index(){
		render('#index_template', {});
	}

	function lga_overview(lga){
		render('#lga_overview_template', {
			lga: lga.lga_data
		});

		var gps = "11.84769 9.623538".split(' ');
		leaflet_overview(gps[0], gps[1]);
	}

	function lga_sector(lga, sector){
		render('#lga_sector_template', {
			lga: lga.lga_data,
			sector: sector
		});
	}

	function facility_overview(lga){
		render('#lga_sector_template', {
			lga: lga.lga_data,
			facilities: facilities,
		});
	}


	// Helper Functions
	function route(view, sector){
		return function(unique_lga){
			var lga = NMIS.lgas[unique_lga];
			if (typeof lga === 'undefined'){
				var url = '/data/new_data/lgas/' + unique_lga + '.json';
				$.getJSON(url, function(lga){
					NMIS.lgas[unique_lga] = lga;
					view(lga, sector);
				});
			} else {
				view(lga, sector);
			}
		}
	}

	function render(template_id, context){
		var template = $(template_id).html();
		context.NMIS = NMIS;
		context.format_value = format_value;
		var html = _.template(template, context);
		$('#content .content').html(html);
	}

	function format_value(value){
		if (typeof value === 'undefined') return '-';
		if (_.isNumber(value) && value % 1 !== 0)
			return value.toFixed(2);
		return value;
	}
})();


function leaflet_overview(latitude, longitude){
	var map_div = $(".map")[0];
	var lat_lng = new L.LatLng(latitude, longitude);
	var map_zoom = 9;
	var summary_map = L.map(map_div, {})
	    .setView(lat_lng, map_zoom);
	var tile_server = 'http://{s}.tiles.mapbox.com/v3/modilabs.nigeria_base'
	    + '/{z}/{x}/{y}.png';
	L.tileLayer(tile_server, {
	  		minZoom: 6,
	  		maxZoom: 1
	  	})
		.addTo(summary_map);
}

function leaflet_countryview(){
};

function leaflet_facility(){
};

