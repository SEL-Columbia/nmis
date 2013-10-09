(function(){
	NMIS = {};
	var template_cache = {};

	$(function(){
		new Backbone.Router({
			routes: {
				'': index,
				':unique_lga': lga_overview,
				//':unique_lga/health': lga_health,
				//':unique_lga/education': lga_education,
				//':unique_lga/water': lga_water,
				//':unique_lga/facility': facility_overview,
				//':unique_lga/facility_health': facility_health,
				//':unique_lga/facility_education': facility_education,	
				//':unique_lga/facility_water': facility_water
			}
		});
		Backbone.history.start();
	});


	// Page Views
	function index(){
		var html = render('#index_template', {});
		$('#content').append(html);
	}

	function lga_overview(unique_lga){
		var lga = NMIS.lgas[unique_lga];
		if (!lga){
			$.getJSON('/data/new_data/lgas/' + unique_lga + '.json', function(data){
				NMIS.lgas[unique_lga] = data;
				lga_overview(unique_lga);
			});
			return;
		}
		var html = render('#lga_overview_template', {
			lga: lga.lga_data
		});
		$('#content').html(html);
	}


	function lga_health(unique_lga){
		// summary_sectors.json: sections & indicator list

	}


	// Helper Functions
	function render(template_id, context){
		var template = $(template_id).html();
		context.NMIS = NMIS;
		context.format_value = format_value;
		return _.template(template, context);
	}


	function format_value(value){
		if (typeof value === 'undefined') return '-';
		if (_.isNumber(value) && value % 1 !== 0)
			return value.toFixed(2);
		return value;
	}
})();

