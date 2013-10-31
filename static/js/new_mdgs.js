$(function(){
    var map = mapInit();
});

var mapboxTileServer = function(indicator) {
    return 'http://{s}.tiles.mapbox.com/v3/modilabs.' +
        indicator + '/{z}/{x}/{y}.png';
};


var mapInit = function() {
    var mapZoom = 6;
    var map_div = $('.mdg-map')[0];
    var lat_lng = new L.LatLng(9.16718, 7.53662);
    var map = new L.Map(map_div).setView(lat_lng, mapZoom);
    var tileset = "nigeria_base";
    var tileServer = mapboxTileServer(tileset);
    var baseLayer = new L.TileLayer(tileServer, {
        minZoom: 6,
        maxZoom: 11
    });
    baseLayer.addTo(map);
    return map;
};

var mapLayerSwitcher = function() {
};
