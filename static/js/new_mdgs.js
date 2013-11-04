$(function(){
    window.map = mapInit();
    //mapLayerInit(map, ['NMIS_gross_enrollment_ratio_secondary_education']);
    $('#mdg-selector').selectize({
        onItemAdd: function(value){
            changeIndicator(value);
        }
    });
});

var mapboxTileLayer = function(indicator, minZoom, maxZoom) {
    var tileServer = 'http://{s}.tiles.mapbox.com/v3/modilabs.' +
        indicator + '/{z}/{x}/{y}.png';
    var tileLayer = new L.TileLayer(tileServer, {
        minZoom: minZoom,
        maxZoom: maxZoom
    });
    return tileLayer;
};

var mapboxLayer = function(indicator, minZoom, maxZoom) {
    var mapboxName = 'modilabs.' + indicator;
    var tileLayer = new L.mapbox.tileLayer(mapboxName, {
        minZoom: minZoom,
        maxZoom: maxZoom,
    });
    return tileLayer;
};

var mapInit = function() {
    var mapZoom = 6;
    var map_div = $('.mdg-map')[0];
    var lat_lng = new L.LatLng(9.16718, 7.53662);
    var sw = new L.LatLng(4.039617826768437, 0.17578125);
    var ne = new L.LatLng(14.221788628397572, 14.897460937499998);
    var country_bounds = new L.LatLngBounds(sw, ne);
    var map = new L.Map(map_div,{
            maxBounds: country_bounds
        }).setView(lat_lng, mapZoom);
    var baseLayer = mapboxLayer('nigeria_base', 6, 9);
    baseLayer.addTo(map);
    var expTile = 'NMIS_gross_enrollment_ratio_secondary_education';
    var expLayer = mapboxLayer(expTile, 6, 9);
    var legend = L.mapbox.legendControl();
    expLayer.on('ready', function(){
        var TileJSON = expLayer.getTileJSON();
        legend.addLegend(TileJSON.legend);
        legend.addTo(map);
    });
    expLayer.addTo(map);
    return map;
};

var mapLayerInit = function(map, layers) {
    _.each(layers, function(layer){
        var tempLayer = mapboxLayer(layer, 6, 9);
    });
};
