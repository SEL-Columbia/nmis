(function(){

var facility_map_obj = false;
    
$(function(){
    new Backbone.Router({
        routes: {
            '': index,
            ':unique_lga/lga_overview': view(LGAView, 'overview'),
            ':unique_lga/lga_health': view(LGAView, 'health'),              
            ':unique_lga/lga_education': view(LGAView, 'education'),
            ':unique_lga/lga_water': view(LGAView, 'water'),
            ':unique_lga/map_overview': view(MapView, 'overview'),
            ':unique_lga/map_health': view(MapView, 'health'),
            ':unique_lga/map_education': view(MapView, 'education'),  
            ':unique_lga/map_water': view(MapView, 'water'),  
            ':unique_lga/table_overview': view(TableView, 'overview'),
            ':unique_lga/table_health': view(TableView, 'health'),
            ':unique_lga/table_education': view(TableView, 'education'),
            ':unique_lga/table_water': view(TableView, 'water')
        }
    });
    Backbone.history.start();
});



// Helper Functions
// =================
function view(viewObj, sector){
    // Wrapper for LGA based views. Fetches the appropriate 
    // LGA JSON data before calling the render() function of a view.

    if (viewObj.init) viewObj.init();

    function render(lga, sector){
        $('.facility_map').hide();
        $(window).scrollTop(0);
        viewObj.render(lga, sector);
    }

    return function(unique_lga){
        var lga = NMIS.lgas[unique_lga];
        if (lga){
            render(lga, sector);
        } else {
            var url = '/static/data/lgas/' + unique_lga + '.json';
            $.getJSON(url, function(lga){
                NMIS.lgas[unique_lga] = lga;
                render(lga, sector);
            });
        }
    }
}

function render_nav(lga, active_view, sector){
    // Renders the LGA navigation bar
    var template = $('#lga_nav_template').html();
    var html = _.template(template, {
        lga: lga,
        active_view: active_view,
        sector: sector
    });
    $('.lga_nav').html(html).show();
}


function render(template_id, context){
    // Renders an underscore template to the dom
    var template = $(template_id).html();
    context.NMIS = NMIS;
    context.format_value = format_value;
    context.indicator_name = indicator_name;
    var html = _.template(template, context);
    $('#content .content').html(html);
}


function format_value(value){
    // Formats indicator values for use in tables
    if (typeof value === 'undefined' ||
        value === null) return '-';
    if (value === true) return 'Yes';
    if (value === false) return 'No';
    if (_.isNumber(value) && value % 1 !== 0)
        return value.toFixed(2);
    if (_.isString(value))
        return value[0].toUpperCase() + value.substr(1);
    return value;
}

function indicator_name(slug){
    var indicator = NMIS.indicators[slug];
    return indicator ? indicator.name : slug;
}



// Views
// ============
function index(){
    $('.lga_nav').hide();
    render('#index_template', {zones: NMIS.zones});
    $('#zone-navigation .state-link').click(function(){
        $(this).next('.lga-list').toggle();
        return false;
    });
};



var LGAView = {};
LGAView.render = function(lga, sector){
    render_nav(lga, 'lga', sector);

    if (sector === 'overview'){
        render('#lga_overview_template', {
            lga: lga,
            lga_overview: NMIS.lga_overview
        });
        this.overview_map(lga);
    } else {
        render('#lga_view_template', {
            lga: lga,
            lga_view: NMIS.lga_view,
            sector: sector
        });
    }
};
LGAView.overview_map = function(lga){
    var map_div = $('.map')[0];
    var lat_lng = new L.LatLng(lga.latitude, lga.longitude);
    var map_zoom = 9;
    var summary_map = L.map(map_div, {scrollWheelZoom: false})
            .setView(lat_lng, map_zoom);
    var tile_server = 'http://{s}.tiles.mapbox.com/v3/' +
        'modilabs.nigeria_base/{z}/{x}/{y}.png';
    L.tileLayer(tile_server, {
        minZoom: 6,
        maxZoom: 11
    }).addTo(summary_map);
};



var MapView = {};
MapView.init = function(){
    $('.map_view_legend').on('click', '.close', function(){
        $(this).parent().hide();
        return false;
    });
};

MapView.render = function(lga, sector){
    var self = this;
    render_nav(lga, 'map', sector);
    render('#map_view_template', {
        lga: lga,
        sector: sector,
        chart_indicators: this.chart_indicators(lga.facilities, sector)
    });
    $('.facility_map').show();
    $('.map_view_legend').hide();
    this.facility_map_switcher(lga, sector);
    $('.pie_chart_selector').change(function(){
        if (this.value){
            $('.map_view_legend').show();
            self.map_legend(lga, sector, this.value);
            self.map_icon_switch(lga, sector, this.value);
        } else {
            $('.map_view_legend').hide();
            self.facility_map_switcher(lga, sector);
        }
    });
};

MapView.chart_indicators = function(facilities, sector){
    // Iterates through facilities within a sector to find
    // indicators which contain boolean values.
    // Returns a list of [indicator, indicator_name]
    var indicators = {};
    for (var i=0, facility; facility=facilities[i]; i++){
        if (facility.sector === sector){
            for (var indicator in facility){
                if (facility.hasOwnProperty(indicator)){
                    var value = facility[indicator];
                    if (value === false || value === true)
                        indicators[indicator] = 1;
                }
            }
        }
    }
    var chart_indicators = [];
    _.each(_.keys(indicators), function(indicator){
        chart_indicators.push([
            indicator, indicator_name(indicator)
        ]);
    });
    chart_indicators.sort(function(a,b){
        if (a[1] > b[1]) return 1;
        else if (a[1] < b[1]) return -1;
        return 0;
    });
    return chart_indicators;
};

MapView.facility_map_switcher = function(lga, sector) {
    if(!facility_map_obj || facility_map_obj.lga !== lga) { 
        if (!facility_map_obj) {
            facility_map_obj = {};
            facility_map_obj.map = this.facilities_map(lga);
        } else {
            facility_map_obj.clean_layers();
            var lat_lng = new L.LatLng(lga.latitude, lga.longitude);
            var map_zoom = 10;
            facility_map_obj.map.setView(lat_lng, map_zoom);
        }
        facility_map_obj.lga = lga;
        facility_map_obj.markers = {
            water : this.mark_facilities(lga.facilities, 'water'),
            education : this.mark_facilities(lga.facilities, 'education'),
            health : this.mark_facilities(lga.facilities, 'health')
        };
        facility_map_obj.clean_layers = function() {
            _.each(facility_map_obj.markers, function(layer){
                facility_map_obj.map.removeLayer(layer);
            });
        };
    }
    facility_map_obj.clean_layers();
    if(sector === 'overview') {
        facility_map_obj.markers.education.addTo(facility_map_obj.map);
        facility_map_obj.markers.water.addTo(facility_map_obj.map);
        facility_map_obj.markers.health.addTo(facility_map_obj.map);
    } else {
        facility_map_obj.markers[sector].addTo(facility_map_obj.map);
    }
}

MapView.map_icon_switch = function(lga, sector, indicator) {
    facility_map_obj.clean_layers();
    facility_map_obj.markers.true_false_markers = this.mark_facilities(lga.facilities, 
            sector, indicator);
    facility_map_obj.markers.true_false_markers.addTo(facility_map_obj.map);
};

MapView.facilities_map = function(lga){
    var map_div = $(".facility_map")[0];
    var lat_lng = new L.LatLng(lga.latitude, lga.longitude);
    var map_zoom = 10; //TODO: adding nw and se for bounding box
    var facility_map = new L.Map(map_div, {scrollWheelZoom: false})
        .setView(lat_lng, map_zoom);
    var tileset = "nigeria_overlays_white";
    var tile_server = "http://{s}.tiles.mapbox.com/v3/modilabs." + tileset +
                      "/{z}/{x}/{y}.png";
    var lga_layer = new L.TileLayer(tile_server, {
        minZoom: 6,
        maxZoom: 10
    });
    var ggl_server = 'http://mt1.google.com/vt/lyrs=y&x={x}&y={y}&z={z}';
    var ggl = new L.TileLayer( ggl_server, {
        maxZoom:18, 
        minZoom:3
    });
    ggl.addTo(facility_map);
    lga_layer.addTo(facility_map);
    return facility_map;
};

MapView.mark_facilities = function(facilities, sector, indicator) {
    var that = this;
    var marker_group = new L.LayerGroup();
    _.each(facilities, function(fac){
        if (fac.sector === sector) {
            var lat_lng = fac.gps.split(" ").slice(0,2);
            var icon_url;
            if (indicator) {
                if (fac[indicator] === true || 
                    fac[indicator] === false) {
                    icon_url = 'static/images/icons_f/' + 
                        fac[indicator] +'.png';
                } else {
                    icon_url = 'static/images/icons_f/' +
                        'undefined.png';
                }
            } else {
                icon_url = 'static/images/icons_f/normal_' + 
                    fac.sector + '.png';
            }
            var icon = new L.Icon({iconUrl: icon_url}); 
            var mark = new L.Marker(lat_lng, {icon: icon});
            var popup = new L.Popup({closeButton: false})
                .setContent(fac.facility_name || 'Water Point')
                .setLatLng(lat_lng);
            mark.on('click', function(){
                that.facility_modal(fac);
            });
            mark.on('mouseover', mark.openPopup.bind(mark))
                .on('mouseout', mark.closePopup.bind(mark))
                .bindPopup(popup);
            marker_group.addLayer(mark);
        }
    });
    return marker_group;
};

MapView.facility_modal = function(facility){
    var that = this;
    var template = $('#facility_modal_template').html();
    var html = _.template(template, {
        NMIS: NMIS,
        facility: facility,
        tables: NMIS.table_view[facility.sector]
    });
    $('#facility_modal').remove();
    $('#content').append(html);
    $('#facility_modal').modal();
    $('.facility_table_selector').change(function(){
        var index = parseInt(this.value);
        that.facility_table(facility, index);
    });
    this.facility_table(facility, 0);
};

MapView.facility_table = function(facility, index){
    var aoColumns = [{sTitle: 'Indicator'}, {sTitle: 'Value'}];
    var table = NMIS.table_view[facility.sector][index];
    var aaData = [];

    _.each(table.indicators, function(indicator){
        aaData.push([
            indicator_name(indicator),
            format_value(facility[indicator])
        ]);
    });
    
    $('.facility_table')
        .dataTable({
            aaData: aaData,
            aoColumns: aoColumns,
            bFilter: false,
            bPaginate: false,
            bDestroy: true
        })
        .width('100%'); 
};

MapView.map_legend = function(lga, sector, indicator){
    var ctx = $('.map_view_legend canvas')[0].getContext('2d');        
    var trues = 0;
    var falses = 0;
    var unknowns = 0;
    _.each(lga.facilities, function(facility){
        if (facility.sector === sector){
            var value = facility[indicator];
            if (value) trues++;
            else if (value === false) falses++;
            else unknowns++;
        }
    });
    var total = trues + falses + unknowns;
    var data = [{
        value: trues / total * 100,
        color: 'rgb(68, 167, 0)'
    }, {
        value : falses / total * 100,
        color : 'rgb(193, 71, 71)'
    }, {
        value : unknowns / total * 100,
        color : '#ddd'
    }];
    new Chart(ctx).Pie(data, {
        animationEasing: 'easeOutQuart',
        animationSteps: 15
    });
    var html = '<h4>' + indicator_name(indicator) + '</h4>';
    html += NMIS.indicators[indicator].description;
    html += '<p class="values">' + trues + ' Yes / ' + falses + ' No';
    if (unknowns)
        html += ' / ' + unknowns + ' Unknown';
    html += '</p>';
    $('.map_view_legend .info').html(html);
};



var TableView = {};
TableView.render = function(lga, sector){
    render_nav(lga, 'table', sector);
    render('#table_view_template', {
        lga: lga,
        sector: sector,
        tables: NMIS.table_view[sector]
    });

    var that = this;
    $('.facilities_table_selector').change(function(){
        var index = parseInt(this.value, 10);
        that.show_table(sector, index, lga.facilities);
    });
    this.show_table(sector, 0, lga.facilities);
};

TableView.show_table = function(sector, table_index, facilities){
    var aoColumns = [];
    var table = NMIS.table_view[sector][table_index];

    _.each(table.indicators, function(indicator){
        aoColumns.push({
            sTitle: indicator_name(indicator)
        });
    });
    
    var aaData = [];
    _.each(facilities, function(facility){
        if (facility.sector === sector || sector === 'overview'){
            var facility_data = [];
            _.each(table.indicators, function(indicator){
                var value = facility[indicator];
                if (!value && facility.sector === 'water')
                    value = 'Water Point';
                value = format_value(value);
                facility_data.push(value);
            });
            aaData.push(facility_data);
        }
    });

    $('#facilities_data_table')
        .find('thead')
        .html('') // http://stackoverflow.com/questions/16290987/how-to-clear-all-column-headers-using-datatables
        .end()
        .dataTable({
            aaData: aaData,
            aoColumns: aoColumns,
            bPaginate: false,
            bDestroy: true,
            bFilter: false
        })
        .width('100%');
};


})();

