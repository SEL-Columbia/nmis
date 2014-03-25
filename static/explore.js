(function(){
    
$(function(){
    new Backbone.Router({
        routes: {
            '': IndexView,
            'walkthrough_end': IndexView,
            'gap_sheets': GapSheetIndexView,
            ':unique_lga/lga_overview': view(LGAView, 'overview'),
            ':unique_lga/lga_health': view(LGAView, 'health'),              
            ':unique_lga/lga_education': view(LGAView, 'education'),
            ':unique_lga/lga_water': view(LGAView, 'water'),
            ':unique_lga/map_overview': view(MapView, 'overview'),
            ':unique_lga/map_health': view(MapView, 'health'),
            ':unique_lga/map_education': view(MapView, 'education'),  
            ':unique_lga/map_water': view(MapView, 'water'),  
            ':unique_lga/facilities_overview': view(FacilitiesView, 'overview'),
            ':unique_lga/facilities_health': view(FacilitiesView, 'health'),
            ':unique_lga/facilities_education': view(FacilitiesView, 'education'),
            ':unique_lga/facilities_water': view(FacilitiesView, 'water'),
            ':unique_lga/gap_sheet_education': view(GapSheetView, 'education'),
            ':unique_lga/gap_sheet_health': view(GapSheetView, 'health')
        }
    });

    MapView.init();
    render_lga_search(NMIS.sorted_lgas);
    Backbone.history.start();
});



// Helper Functions
// ===========================================

function view(viewObj, sector){
    // Wrapper for LGA based views. Fetches the appropriate 
    // LGA JSON data before calling the render() function of a view.

    function render_wrap(lga, sector){
        $('.map_view, .loading').hide();
        $('#content').stop().css('opacity', 1);
        $('#content .index').removeClass('index');
        $('#content .container').show();
        $(window).scrollTop(0);
        viewObj.render(lga, sector);
        Walkthrough.show();
    }

    return function(unique_lga){
        var lga = NMIS.lgas[unique_lga];
        if (lga){
            render_wrap(lga, sector);
        } else {
            $('.loading').show();
            $('#content').fadeTo(100, 0.5);
            var url = '/static/lgas/' + unique_lga + '.json';
            $.getJSON(url, function(lga){
                NMIS.lgas[unique_lga] = lga;
                render_wrap(lga, sector);
            });
        }
    }
}


function render_header(lga, active_view, sector){
    // Renders the LGA navigation bar
    var template = $('#explore_header_template').html();
    var html = _.template(template, {
        lga: lga,
        active_view: active_view,
        sector: sector
    });
    $('#explore_header').html(html).show();
}


function render_lga_search(sorted_lgas){
    // Renders the LGA Search box
    var template = $('#lga_search_template').html();
    var html = _.template(template, {sorted_lgas: sorted_lgas});
    $('#lga_search')
        .html(html)
        .show()
        .find('select')
        .selectize({
            onItemAdd: function(value){
                location.hash = '#' + value + '/lga_overview';
                this.clear();
                return false;
            }  
        });
}


function render(template_id, context){
    // Renders an underscore template to the dom
    var template = $(template_id).html();
    context.NMIS = NMIS;
    context.format_value = format_value;
    context.indicator_name = indicator_name;
    context.indicator_description = indicator_description;
    var html = _.template(template, context);
    $('#content .content').html(html);
}


function format_value(value){
    // Formats indicator values for use in tables
    if (typeof value === 'undefined' ||
        value === null) return 'NA';
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


function indicator_description(slug){
    var indicator = NMIS.indicators[slug];
    return indicator ? indicator.description : slug;
}



// Views
// ===========================================
function IndexView(){
    render('#index_template', {
        zones: NMIS.zones,
        active_view: null
    });

    $('#explore_header, .map_view').hide();
    $('#content .content').addClass('index');

    $('#zone_nav .state_title').click(function(){
        $(this).next('.lgas').toggle();
        return false;
    });
    Walkthrough.show();
};


function GapSheetIndexView(){
    render('#index_template', {
        zones: NMIS.zones,
        active_view: 'gap_sheet'
    });

    $('#header .global_nav, #lga_search').hide()
    $('#explore_header, .map_view').hide();
    $('.gap_sheet_nav').show();
    $('#content .content').addClass('index');

    $('#zone_nav .state_title').click(function(){
        $(this).next('.lgas').toggle();
        return false;
    });
};



var LGAView = {};
LGAView.render = function(lga, sector){
    render_header(lga, 'lga', sector);

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
    var map_div = $('.map_overview')[0];
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
    // Runs after page load
    // Append map outside of .container so it can fill the width of the page
    $('#content').append(
        $('#map_view_template').html());
    $('.map_view').hide();

    $('.map_legend').on('click', '.close', function(){
        $(this).parent().hide();
        $('.pie_chart_selector')
            .prop('selectedIndex', 0)
            .change();
        return false;
    });
};

MapView.render = function(lga, sector){
    render_header(lga, 'map', sector);

    $('#content .container').hide();
    $('.map_legend').hide();

    this.facility_map(lga, sector);
    this.pie_chart_selector(lga, sector);
};

MapView.facility_map = function(lga, sector, indicator) {
    var lat_lng = new L.LatLng(lga.latitude, lga.longitude);
    var map_height = $(document).height() - $('#header').outerHeight() + 5;
    var map_div = $('.map_view')
        .height(map_height)
        .show()[0];
    var map = map_div._map;

    if (!map){
        // Initialize Leaflet
        map = new L.Map(map_div, {scrollWheelZoom: false})
            .setView(lat_lng, 11);
        var lga_layer = new L.TileLayer(
            'http://{s}.tiles.mapbox.com/v3/modilabs.nigeria_overlays_white/{z}/{x}/{y}.png', {
                minZoom: 6,
                maxZoom: 14
            });
        var locality_layer = new L.TileLayer(
            'http://{s}.tiles.mapbox.com/v3/modilabs.Nigeria_Localities/{z}/{x}/{y}.png', {
                minZoom: 13,
                maxZoom: 18
            });
        var google_layer = new L.TileLayer(
            'http://mt1.google.com/vt/lyrs=y&x={x}&y={y}&z={z}', {
                maxZoom: 18, 
                minZoom: 3
            });
        google_layer.addTo(map);
        lga_layer.addTo(map);
        locality_layer.addTo(map);
        map_div._map = map;
        map._unique_lga = lga.unique_lga;
    }

    if (map._facility_layer)
        map.removeLayer(map._facility_layer);

    if (map._unique_lga !== lga.unique_lga){
        map._unique_lga = lga.unique_lga;
        map.setView(lat_lng, 11);
    }
    map._facility_layer = this.facility_layer(lga.facilities, sector, indicator);
    map._facility_layer.addTo(map);
};

MapView.facility_layer = function(facilities, sector, indicator) {
    var that = this;
    var marker_group = new L.LayerGroup();

    _.each(facilities, function(fac){
        if (fac.sector === sector || sector === 'overview') {
            var lat_lng = fac.gps.split(' ').slice(0,2);
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
                .setContent(fac.facility_name)
                .setLatLng(lat_lng);
            mark.on('click', function(){
                that.facility_modal(fac);
            });
            mark.on('mouseover', mark.openPopup.bind(mark))
                .on('mouseout', mark.closePopup.bind(mark))
                .bindPopup(popup, {offset: new L.Point(14, 7)});
            marker_group.addLayer(mark);
        }
    });
    return marker_group;
};

MapView.pie_chart_selector = function(lga, sector){
    var self = this;
    var chart_indicators = this.chart_indicators(lga.facilities, sector);
    
    if (chart_indicators.length) {
        var template = $('#pie_chart_selector_template').html();
        var html = _.template(template, {
            lga: lga,
            sector: sector,
            chart_indicators: chart_indicators
        });
        var selector = $('.pie_chart_selector')
            .html(html)
            .show()
            .change(function(){
                if (this.value){
                    $('.map_legend').show();
                    self.map_legend(lga, sector, this.value);
                } else {
                    $('.map_legend').hide();
                }
                self.facility_map(lga, sector, this.value);
                return false;
            });

        // Prevent click selection from "falling through" to map
        L.DomEvent.disableClickPropagation(selector[0]);
    } else {
        $('.pie_chart_selector').hide();
    }
};

MapView.chart_indicators = function(facilities, sector){
    // Iterates through facilities within a sector to find
    // indicators which contain boolean values.
    // Returns a sorted list of [indicator, indicator_name]
    var relevant_indicators = [];
    _.each(NMIS.facilities_view[sector], function(sec){
        _.each(sec.indicators, function(ind){
            relevant_indicators.push(ind);
        });
    });
    var indicators = {};
    for (var i=0, facility; facility=facilities[i]; i++){
        if (facility.sector === sector){
            for (var indicator in facility){
                if (relevant_indicators.indexOf(indicator) > 0){
                    if (facility.hasOwnProperty(indicator)){
                        var value = facility[indicator];
                        if (value === false || value === true)
                            indicators[indicator] = 1;
                    }
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

MapView.facility_modal = function(facility){
    var that = this;
    var template = $('#facility_modal_template').html();
    var html = _.template(template, {
        NMIS: NMIS,
        facility: facility,
        tables: NMIS.facilities_view[facility.sector]
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
    var table = NMIS.facilities_view[facility.sector][index];
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
            bDestroy: true,
            sDom: '<"top">rt<"bottom"flp><"clear">'
        })
        .width('100%'); 
};

MapView.map_legend = function(lga, sector, indicator){
    var ctx = $('.map_legend canvas')[0].getContext('2d');        
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
    var percent_complete = trues ? (trues / total * 100).toFixed(0): 0;
    var pie_data = [{
            value: trues / total * 100,
            color: '#071efb'
        }, {
            value : falses / total * 100,
            color : '#cc0202'
        }, {
            value : unknowns / total * 100,
            color : '#e6e6e6'
        }];

    new Chart(ctx).Pie(pie_data, {
        animationEasing: 'easeOutQuart',
        animationSteps: 15
    });
    
    var html = '<h4>' + indicator_name(indicator) + ' (' + percent_complete + '%)</h4>';
    html += NMIS.indicators[indicator].description;
    html += '<p class="values">' +
        '<span class="trues"><img src="static/images/icons_f/true.png">' + 
            trues + ' Yes</span>' +
        '<span class="falses"><img src="static/images/icons_f/false.png">' + 
            falses + ' No</span>';
    if (unknowns){
        html += '<span class="unknowns"><img src="static/images/icons_f/undefined.png">' + 
            unknowns + ' Unknown</span>';
    }
    html += '</p>';
    $('.map_legend .info').html(html);
};



var FacilitiesView = {};
FacilitiesView.render = function(lga, sector){
    render_header(lga, 'facilities', sector);
    render('#facilities_view_template', {
        lga: lga,
        sector: sector,
        tables: NMIS.facilities_view[sector]
    });

    var that = this;
    $('.facilities_table_selector').change(function(){
        var index = parseInt(this.value, 10);
        that.show_table(sector, index, lga.facilities);
    });
    this.show_table(sector, 0, lga.facilities);
};

FacilitiesView.show_table = function(sector, table_index, facilities){
    var aoColumns = [];
    var table = NMIS.facilities_view[sector][table_index];
    var tableWidth = $('#content .container').width() - 400;
    var colWidth = Math.floor(tableWidth / (table.indicators.length - 2));

    _.each(table.indicators, function(indicator, i){
        var aoColumn = {sTitle: indicator_name(indicator)};
        if (i < 2){
            aoColumn.sWidth = '195px';
        } else {
            aoColumn.sWidth = colWidth - 6 + 'px';
        }
        aoColumns.push(aoColumn);
    });
    
    var aaData = [];
    _.each(facilities, function(facility){
        if (facility.sector === sector || (sector === 'overview' && facility.sector !== 'water')){
            var facility_data = [];
            _.each(table.indicators, function(indicator){
                var value = facility[indicator];
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
            bAutoWidth: false,
            bFilter: false,
            sDom: '<"top">rt<"bottom"flp><"clear">'
        })
        .width('100%');
};



var GapSheetView = {};
GapSheetView.render = function(lga, sector){
    $('#header .global_nav, #lga_search').hide();
    $('.gap_sheet_nav').show();

    render_header(lga, 'gap_sheet', sector);
    render('#gap_sheet_template', {
        lga: lga,
        sector: sector,
        gap_sheet: NMIS.gap_sheet_view[sector],
        num_true_indicator: this.num_true_indicator,
        num_bool_indicator: this.num_bool_indicator
    });
};
GapSheetView.num_true_indicator = function(indicator, sector, facilities){
    var num_true = 0;
    for (var f, i=0; f=facilities[i]; i++){
        if (f.sector === sector && f[indicator] === true)
            num_true += 1;
    }
    return num_true;
};
GapSheetView.num_bool_indicator = function(indicator, sector, facilities){
    var num_bool = 0;
    for (var f, i=0; f=facilities[i]; i++){
        if (f.sector === sector && typeof f[indicator] === 'boolean')
            num_bool += 1;
    }
    return num_bool;
};



var Walkthrough = {};
Walkthrough.show = function(index){
    if ($.cookie('hide_walkthrough')){
        return;
    } else if (typeof index === 'undefined'){
        // Find the page which matches with location.hash
        var page = null;
        var index = null;
        $.each(this.pages, function(i, p){
            if (p.location_hash === window.location.hash){
                page = p;
                index = i;
                return false;
            }
        });
        if (page === null) return;
    } else {
        var page = this.pages[index];
    }

    var template = $('#walkthrough_modal_template').html();
    var html = _.template(template, {
        body: page.body,
        index: index
    });

    $('.walkthrough_modal, .curved_arrow').remove();

    window.location.hash = page.location_hash;

    var modal = $(html).appendTo('#content');
    modal.show()
        .find('.walkthrough_back, .walkthrough_next')
        .click(function(){
            var i = $(this).data('index');
            Walkthrough.show(i);
        })
        .end()
        .find('.walkthrough_close')
        .click(Walkthrough.hide)
        .end()
        .find('.dot[data-index="' + index + '"]')
        .addClass('active')
        .end()
        .find('.dot')
        .click(function(){
            var i = $(this).data('index');
            Walkthrough.show(index + 1);
        });

    if (page.callback){
        // Callback that runs after modal is added to DOM
        page.callback.call(modal[0], index); 
    }
};

Walkthrough.hide = function(){
    $('.walkthrough_modal, .curved_arrow').remove();
    $.cookie('hide_walkthrough', '1');
};

Walkthrough.pages = [
    {
        body: "<h1>New to NMIS?</h1>" +
        "Before you get started, we'd like to show you a few tips on exploring facilities" +
        '<div class="walkthrough_btn">Take Tour</div>',
        location_hash: '',
        callback: function(index){
            $(this).find('.walkthrough_nav')
                .hide()
                .end()
                .find('.walkthrough_btn')
                .click(function(){
                    Walkthrough.show(index + 1);
                });
        }
    },
    {
        body: "<h1>Choose an LGA to get started</h1>" +
        "LGAs are organized by zone. Click on a State for a list of LGAs within that State or search for an LGA in the dropdown menu above.",
        location_hash: '',
        callback: function(index){
            // Show 3rd LGA menu
            $('.lgas:eq(0)').show()
                .find('a')
                .click(function(){
                    Walkthrough.show(index + 1);
                    return false;
                });
            
            $.curvedArrow({
                p0x: 400, p0y: 400,
                p1x: 300, p1y: 300,
                p2x: 250, p2y: 440
            });
        }
    },
    {
        body: "<h1>Filter by Sector</h1>" +
        "View all sectors within an LGA or choose from Health, Education or Water.",
        location_hash: '#benue_apa/lga_overview',
        callback: function(index){
            $.curvedArrow({
                p0x: 400, p0y: 400,
                p1x: 300, p1y: 400,
                p2x: 300, p2y: 235
            });
        }
    },
    {
        body: "<h1>Multiple Views</h1>" +
        "You can easily switch between an LGA overview, map of facilities, or individual facility data by selecting the<br> appropriate tab.",
        location_hash: '#benue_apa/lga_health',
        callback: function(index){
            $.curvedArrow({
                p0x: 950, p0y: 400,
                p1x: 1070, p1y: 400,
                p2x: 1070, p2y: 225
            });
        }  
    },
    {
        body: "<h1>Indicator Detail in Mapview</h1>" +
        "View which or how many facilities provide a specific service, by selecting the indicator from the dropdown.",
        location_hash: '#benue_apa/map_health',
        callback: function(){
            $('.walkthrough_modal').css({
                top: 75,
                left: '65%'
            });

            $.curvedArrow({
                p0x: 600, p0y: 450,
                p1x: 400, p1y: 450,
                p2x: 400, p2y: 300
            })
            .delay(1000)
            .fadeOut(function(){
                $('.pie_chart_selector')
                    .find('option[value="child_health_measles_immun_calc"]')
                    .prop('selected', 'selected')
                    .end()
                    .change();
            });
        }
    },
    {
        body: "<h1>Facility Snapshot and Detail</h1>" +
        "View the Snapshot, the most relevant indicators for each facility, or view more detailed indicators such as those for Infrastructure or Staffing.",
        location_hash: '#benue_apa/facilities_health',
        callback: function(){
            $('.walkthrough_modal').css('top', 200);
            
            $.curvedArrow({
                p0x: 400, p0y: 450,
                p1x: 300, p1y: 450,
                p2x: 300, p2y: 310
            });
        }
    },
    {
        body: '<h1 class="white">Okay, I\'ve got it</h1>' +
        '<div class="walkthrough_btn">Start Exploring</div><br>' +
        'Need more help? View additional <a href="/planning">Planning Tools</a>',
        location_hash: '#walkthrough_end',
        callback: function(){
            $('.walkthrough_next').hide();
            $(this).find('.walkthrough_btn')
                .click(function(){
                    Walkthrough.hide();
                    $('.walkthrough_modal').remove();
                });
        }
    }
];



})();

