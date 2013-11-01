$(function(){
    window.map = mapInit();
    mapLayerInit(map, 'NMIS_gross_enrollment_ratio_secondary_education');
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
    var baseTile = "nigeria_base";
    var baseLayer = mapboxTileLayer(baseTile, 6, 11);
    baseLayer.addTo(map);
    return map;
};

var mapLayerInit = function(map, layers) {
    var tempSever = mapboxTileLayer(layers, 6, 9);
};
