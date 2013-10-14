(function(){
  $(function(){
    leaflet_mdgs();
  });
}();

function leaflet_mdgs(){
  var map_div = $(".map")[0];
  debugger;
  var lat_lng = new L.LatLng(lga.latitude, lga.longitude);
  var map_zoom = 9;
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
