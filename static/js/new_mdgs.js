$(function(){
    mapInit();
});

var mapInit = function() {
    var mapZoom = 6;
    var map_div = $('.mdg-map')[0];
    var lat_lng = new L.LatLng(9.16718, 7.53662);
    var map = new L.Map(map_div).setView(lat_lng, mapZoom);
    var tileset = "nigeria_base";
    var tileServer = 'http://{s}.tiles.mapbox.com/v3/' +
        'modilabs.nigeria_base/{z}/{x}/{y}.png';
    var baseLayer = new L.TileLayer(tileServer, {
        minZoom: 6,
        maxZoom: 11
    });
    baseLayer.addTo(map);
};

var mapLayerSwitcher = function() {
};
