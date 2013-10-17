$(function(){
    leaflet_mdgs();
});

NMIS.centroid = {lat: 9.16718,
                 lng: 7.53662};

function leaflet_mdgs(){
    var map_div = $(".mdg-map")[0];
    var lat_lng = new L.LatLng(NMIS.centroid.lat, NMIS.centroid.lng);
    var map_zoom = 6;
    var summary_map = L.map(map_div, {})
            .setView(lat_lng, map_zoom);
    var tileset = "nigeria_base";
    var tile_server = "http://{s}.tiles.mapbox.com/v3/modilabs."
                      + tileset
                      + "/{z}/{x}/{y}.png";
    L.tileLayer(tile_server, {
        minZoom: 6,
        maxZoom: 11
    }).addTo(summary_map);
}
