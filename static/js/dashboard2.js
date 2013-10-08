$(function(){
	new Backbone.Router({
		routes: {
			'': country_view,
			//':unique_lga': lga_overview,
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

	function country_view(){
		var template = _.template($('#country_view_template').html());
		var html = template({zones: ZONES});
		$('#content').append(html);
	}
});

