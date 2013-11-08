$(function(){
    var map_div = $('.mdg-map')[0];
    mapInit(map_div);
    $('#mdg-selector').change(function(){
        applyMap(map_div, this.value);
        applyDescription(this.value);
    });
});

var mapboxLayer = function(indicator, minZoom, maxZoom) {
    var mapboxName = 'modilabs.' + indicator;
    var tileLayer = new L.mapbox.tileLayer(mapboxName, {
        minZoom: minZoom,
        maxZoom: maxZoom,
    });
    return tileLayer;
};

var mapInit = function(map_div) {
    var mapZoom = 6;
    var lat_lng = new L.LatLng(9.16718, 7.53662);
    var sw = new L.LatLng(4.039617826768437, 0.17578125);
    var ne = new L.LatLng(14.221788628397572, 14.897460937499998);
    var country_bounds = new L.LatLngBounds(sw, ne);
    var map = new L.Map(map_div,{
            maxBounds: country_bounds
        }).setView(lat_lng, mapZoom);
    var baseLayer = mapboxLayer('nigeria_base', 6, 9);
    baseLayer.addTo(map);
    map_div.map = map;
    map_div.mapLayers = {};
    map_div.currentLayer = {};
};

var cleanMap = function(map_div) {
    var currentLayer = map_div.currentLayer;
    var map = map_div.map;
    var legend = currentLayer.legend;
    var layer = currentLayer.layer;
    legend.removeFrom(map);
    map.removeLayer(layer);
};

var addMapLayer = function(map, layer) {
    var legend = L.mapbox.legendControl();
    var tempLayer = mapboxLayer(layer, 6, 9);
    tempLayer.on('ready', function(){
        var TileJSON = tempLayer.getTileJSON();
        legend.addLegend(TileJSON.legend);
    });
    return {layer: tempLayer, legend: legend};
};

var applyMap = function(map_div, value) {
    if(!(_.isEmpty(map_div.currentLayer))) { cleanMap(map_div); }
    if(!(map_div.mapLayers[value])) {
        map_div.mapLayers[value] = addMapLayer(map_div.map, value);
    }
    map_div.currentLayer = map_div.mapLayers[value];
    map_div.map.addLayer(map_div.mapLayers[value].layer);
    map_div.mapLayers[value].legend.addTo(map_div.map);
};

var applyDescription = function(value) {
};
