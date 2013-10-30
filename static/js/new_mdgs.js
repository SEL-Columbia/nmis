$(function(){
    map_init();
});

var map_init = function() {
    var mapZoom = 6;
    var map_div = $('.mdg-map')[0];
    var lat_lng = new L.LatLng(9.16718, 7.53662);
    var map = new L.Map(map_div).setView(lat_lng, mapZoom);
    var tileset = "nigeria_base";
    var tileServer = 'http://{s}.tiles.mapbox.com/v3/' +
        'modilabs.nigeria_base/{z}/{x}/{y}.png';
    L.tileLayer(tileServer, {
        minZoom: 6,
        maxZoom: 11
    }).addTo(map);
};
