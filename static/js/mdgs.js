$(function(){
    var globalMap = map = newMDGsMap();
//    var tileLayers = {},
    tileLayers = {};


    initTileLayersFromIndicatorNames(
        ['NMIS_gross_enrollment_ratio_secondary_education'],
        map);

    
    // Creates a new MDGs map (with nothing but centering information)
    function newMDGsMap() {
        //ex: NMIS_gross_enrollment_ratio_secondary_education
        var centroid = {lat: 9.16718, lng: 7.53662};
        var mapZoom = 6;
        return L.map('mdg-map', {
            center: new L.LatLng(centroid.lat, centroid.lng),
            zoom: mapZoom,
        });
    }

    // Adds a tile layer per indicator in indicatorNames, as well as an
    // extra: nigeria_base
    function initTileLayersFromIndicatorNames(indicatorNames, map) {
        var mapboxURL = 'https://{s}.tiles.mapbox.com/v3/{user}.{map}/{z}/{x}/{y}.png';
        var layers = indicatorNames.concat(['nigeria_base']);
        layers.forEach(function(layerName) {
            var thisLayer = L.tileLayer(mapboxURL, 
                                    {user: 'modilabs', map: layerName})
                            .addTo(map);
            tileLayers[layerName] = thisLayer;
        });
    }

    // Change indicator layer
    function changeIndicator(indicatorName) {
        tileLayers[indicatorName].bringToFront();
    }
});
var globalMap, tileLayers;



