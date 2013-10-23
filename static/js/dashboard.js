(function(){
    var template_cache = {};
    
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
        $('#lga_nav').html(html);
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
        var summary_map = L.map(map_div, {})
                .setView(lat_lng, map_zoom);
        var tile_server = 'http://{s}.tiles.mapbox.com/v3/modilabs.nigeria_base/{z}/{x}/{y}.png';
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


    function map_view(lga, sector){
        _lga_nav(lga, 'map', sector);
        render('#map_view_template', {lga: lga});
        facilities_map(lga, sector);
    }


    function facilities_map(lga, current_sector){
        var map_div = $("#facility_map")[0];
        var lat_lng = new L.LatLng(lga.latitude, lga.longitude);
        var map_zoom = 10; //TODO: adding nw and se for bounding box
        var facility_map = new L.Map(map_div, { })
            .setView(lat_lng, map_zoom);
        var tileset = "nigeria_overlays_white";
        var tile_server = "http://{s}.tiles.mapbox.com/v3/modilabs." +
                          tileset +
                          "/{z}/{x}/{y}.png";
        var lga_layer = new L.TileLayer(tile_server, {
            minZoom: 6,
            maxZoom: 10
        });
        var osm_server = "http://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png";
        var osm_layer = new L.TileLayer(osm_server, {
            minZoom: 0,
            maxZoom: 18
        });
        var google_layer = new L.Google("HYBRID", {
            minZoom: 0,
            maxZoom: 18
        });
        var ggl_server = 'http://mt1.google.com/vt/lyrs=y&x={x}&y={y}&z={z}';
        var ggl = new L.TileLayer( ggl_server, {
            maxZoom:18, 
            minZoom:3
        });
        //facility_map.addLayer(google_layer);
        ggl.addTo(facility_map);
        lga_layer.addTo(facility_map);

        var facilities = lga.facilities;
        var icon_state = function(sector, current_sec){
            var state;
            if (current_sec){
                state = sector == current_sec ? 'normal' : 'background';
            } else {
                state = 'normal';
            }
            return state;
        };
        var marker_group = new L.LayerGroup();
        _.each(lga.facilities, function(fac){
            var gps = fac.gps.split(" ");
            var sector = fac.sector;
            var state = icon_state(sector, current_sector);
            var icon_url = 'static/images/icons_f/' + 
                state + '_' + sector + '.png';
            var icon = new L.Icon({iconUrl: icon_url}); 
            var mark = new L.Marker([gps[0], gps[1]], {icon: icon});
            var popup_name = fac.facility_name || 'Water Point';
            var popup = new L.Popup({closeButton: false})
                .setContent("<p>" + popup_name + "</p>")
                .setLatLng([gps[0],gps[1]]);
            mark.on('click', function(){
                
                show_facility_modal(fac);
            });
            mark.on('mouseover', mark.openPopup.bind(mark))
                .on('mouseout', mark.closePopup.bind(mark))
                .bindPopup(popup);
            marker_group.addLayer(mark);
        });
        marker_group.addTo(facility_map);
    }


    function table_view(lga, sector){
        _lga_nav(lga, 'table', sector);
        render('#table_view_template', {lga: lga, sector: sector});

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
                sTitle: NMIS.indicators[indicator].name
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


    function show_facility_modal(facility){
        var template = $('#facility_modal_template').html();
        var html = _.template(template, {
            NMIS: NMIS,
            facility: facility
        });
        $('#facility_modal').remove();
        $('#content').append(html);
        $('#facility_modal').modal();
        $('.facility_table_selector').change(function(){
            var index = parseInt(this.value);
            show_facility_table(facility, index);
        });
        show_facility_table(facility, 0);
    }


    function show_facility_table(facility, index){
        var aoColumns = [{sTitle: 'Indicator'}, {sTitle: 'Value'}];
        var table = NMIS.facility_tables[facility.sector][index];
        var aaData = [];

        _.each(table.indicators, function(indicator){
            aaData.push([
                NMIS.indicators[indicator].name,
                format_value(facility[indicator])
            ]);
        });
        
        $('.facility_table')
            .dataTable({
                aaData: aaData,
                aoColumns: aoColumns,
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
        var html = _.template(template, context);
        $('#content .content').html(html);
    }


    function format_value(value){
        if (typeof value === 'undefined' ||
            value === null) return '-';
        if (value === true) return 'Yes';
        if (value === false) return 'No';
        if (_.isNumber(value) && value % 1 !== 0)
            return value.toFixed(2);
        return value;
    }
})();

