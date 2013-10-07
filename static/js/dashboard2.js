$(function(){
	var template = _.template($('#country_view_tmpl').html());
	var html = template({zones: ZONES});
	$('#content').append(html);



});

