(function(){
    var template_cache = {};
    var facility_map_obj = false;
    
    $(function(){
        new Backbone.Router({
            routes: {
                '': index_view,
                ':unique_lga/lga_overview': route(lga_overview),
                ':unique_lga/lga_health': route(lga_view, 'health'),              
                ':unique_lga/lga_education': route(lga_view, 'education'),
                ':unique_lga/lga_water': route(lga_view, 'water'),
                ':unique_lga/map_overview': route(map_view, 'overview'),
                ':unique_lga/map_health': route(map_view, 'health'),
                ':unique_lga/map_education': route(map_view, 'education'),  
                ':unique_lga/map_water': route(map_view, 'water'),  
                ':unique_lga/table_overview': route(table_view, 'overview'),
                ':unique_lga/table_health': route(table_view, 'health'),
                ':unique_lga/table_education': route(table_view, 'education'),
                ':unique_lga/table_water': route(table_view, 'water')
            }
        });
        Backbone.history.start();
    });
    
    

    // Views
    // ============
    function _lga_nav(lga, active_view, sector){
        var template = $('#lga_nav_template').html();
        var html = _.template(template, {
            lga: lga,
            active_view: active_view,
            sector: sector
        });
        $('.lga_nav').html(html);
    }


    function index_view(){
        render('#index_template', {});
        $('#zone-navigation .state-link').click(function(){
            $(this).next('.lga-list').toggle();
            return false;
        });
    }


    function lga_overview(lga){
        _lga_nav(lga, 'lga', 'overview');
        render('#lga_overview_template', {lga: lga});

        // Leaflet map
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
    }


    function lga_view(lga, sector){
        _lga_nav(lga, 'lga', sector);
        render('#lga_sector_template', {
            lga: lga,
            sector: sector
        });
    }

    function facility_map_switcher(lga, sector) {
        if(!facility_map_obj || facility_map_obj.lga !== lga) { 
            if (!facility_map_obj) {
                facility_map_obj = {};
                facility_map_obj.map = facilities_map(lga);
            } else {
                facility_map_obj.clean_layers();
                var lat_lng = new L.LatLng(lga.latitude, lga.longitude);
                var map_zoom = 10;
                facility_map_obj.map.setView(lat_lng, map_zoom);
            }
            facility_map_obj.lga = lga;
            facility_map_obj.markers = {
                water : mark_facilities(lga.facilities, 'water'),
                education : mark_facilities(lga.facilities, 'education'),
                health : mark_facilities(lga.facilities, 'health')
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


    function map_view(lga, sector){
        _lga_nav(lga, 'map', sector);
        render('#map_view_template', {
            lga: lga,
            chart_indicators: _chart_indicators(lga.facilities, sector)
        });
        facility_map_switcher(lga, sector);
        $('.pie_chart_selector').change(function(){
            if (this.value){
                $('.map_view_legend').show();
                map_legend(lga, sector, this.value);
                map_icon_switch(lga, sector, this.value);
            } else {
                $('.map_view_legend').hide();
                facility_map_switcher(lga, sector);
            }
        });
    }

    function map_icon_switch(lga, sector, indicator) {
        facility_map_obj.clean_layers();
        facility_map_obj.markers.true_false_markers = mark_facilities(lga.facilities, 
                sector, indicator);
        facility_map_obj.markers.true_false_markers.addTo(facility_map_obj.map);
    }


    function _chart_indicators(facilities, sector){
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
    }


    function facilities_map(lga){
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
    }

    function mark_facilities(facilities, sector, indicator) {
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
                    facility_modal(fac);
                });
                mark.on('mouseover', mark.openPopup.bind(mark))
                    .on('mouseout', mark.closePopup.bind(mark))
                    .bindPopup(popup);
                marker_group.addLayer(mark);
            }
        });
        return marker_group;
    }

    function map_legend(lga, sector, indicator){
        var ctx = $('.map_view_legend canvas')[0].getContext('2d');        
        var trues = 0;
        var falses = 0;
        var undefineds = 0;
        _.each(lga.facilities, function(facility){
            if (facility.sector === sector){
                var value = facility[indicator];
                if (value) trues++;
                if (value === false) falses++;
                if (typeof value === 'undefined') undefineds++;
            }
        });
        var total = trues + falses + undefineds;
        var data = [
            {
                value: trues / total * 100,
                color: 'rgb(68, 167, 0)'
            }, {
                value : falses / total * 100,
                color : 'rgb(193, 71, 71)'
            }, {
                value : undefineds / total * 100,
                color : '#ddd'
            }
        ];
        new Chart(ctx).Pie(data, {
            animationEasing: 'easeOutQuart',
            animationSteps: 15
        });

        $('.map_view_legend .info').html(
            '<h4>' + indicator_name(indicator) + 
            ' (' + trues + '/' + total + ')</h4>' +
            NMIS.indicators[indicator].description);
    }


    function table_view(lga, sector){
        _lga_nav(lga, 'table', sector);
        render('#table_view_template', {
            lga: lga,
            tables: NMIS.facility_tables[sector]
        });

        $('.facilities_table_selector').change(function(){
            var index = parseInt(this.value, 10);
            facilities_table(sector, index, lga.facilities);
        });
        facilities_table(sector, 0, lga.facilities);
    }


    function facilities_table(sector, table_index, facilities){
        var aoColumns = [];
        var table = NMIS.facility_tables[sector][table_index];

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
                    var value = format_value(facility[indicator]);
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
                bDestroy: true
            })
            .width('100%');
    }

    function facility_modal(facility){
        var template = $('#facility_modal_template').html();
        var html = _.template(template, {
            NMIS: NMIS,
            facility: facility,
            tables: NMIS.facility_tables[facility.sector]
        });
        $('#facility_modal').remove();
        $('#content').append(html);
        $('#facility_modal').modal();
        $('.facility_table_selector').change(function(){
            var index = parseInt(this.value);
            facility_table(facility, index);
        });
        facility_table(facility, 0);
    }


    function facility_table(facility, index){
        var aoColumns = [{sTitle: 'Indicator'}, {sTitle: 'Value'}];
        var table = NMIS.facility_tables[facility.sector][index];
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
    }



    // Helper Functions
    // ==========================
    function route(view, sector){
        return function(unique_lga){
            var lga = NMIS.lgas[unique_lga];
            if (lga){
                view(lga, sector);
            } else {
                var url = '/static/lgas/' + unique_lga + '.json';
                $.getJSON(url, function(lga){
                    NMIS.lgas[unique_lga] = lga;
                    view(lga, sector);
                });
            }
        };
    }


    function render(template_id, context){
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


    function indicator_name(indicator){
        var indicator = NMIS.indicators[indicator];
        return indicator ? indicator.name : indicator;
    }
})();

