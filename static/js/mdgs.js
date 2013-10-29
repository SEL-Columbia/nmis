// $(function() {   // NON-DEBUGGING
     var map, tileLayers;
    var mapLegend, currentlyDisplayedIndicator;
    
$(function(){ // DEBUGGING VERSION
    map = newMDGsMap();
    tileLayers = {},

    initTileLayersFromIndicatorNames(
        ['NMIS_gross_enrollment_ratio_secondary_education',
         'NMIS_percentage_households_with_access_to_improved_sanitation'],
        map);
}); // DEBUGGING VERSION

    
    // Creates a new MDGs map (with nothing but centering information)
    function newMDGsMap() {
        //ex: NMIS_gross_enrollment_ratio_secondary_education
        var centroid = {lat: 9.16718, lng: 7.53662};
        var mapZoom = 6;
        var map = L.map('mdg-map', {
            center: new L.LatLng(centroid.lat, centroid.lng),
            zoom: mapZoom,
        });
        mapLegend = L.mapbox.legendControl().addTo(map);
        return map;
    }

    // Adds a tile layer per indicator in indicatorNames, as well as an
    // extra: nigeria_base
    function initTileLayersFromIndicatorNames(indicatorNames, map) {
        //var mapboxURL = 'https://{s}.tiles.mapbox.com/v3/{user}.{map}/{z}/{x}/{y}.png';
        var layers = indicatorNames.concat(['nigeria_base']);
        layers.forEach(function(layerName) {
            var thisLayer = L.mapbox.tileLayer('modilabs.' + layerName)
                            .addTo(map);
            tileLayers[layerName] = thisLayer;
        });
    }

    // Change indicator layer
    function changeIndicator(indicatorName) {
        var justDisplayedIndicator = currentlyDisplayedIndicator;
        currentlyDisplayedIndicator = indicatorName;

        // justDisplayedIndicator doesn't exist on first change, no removals necessary
        if (justDisplayedIndicator) {
            tileLayers[justDisplayedIndicator].bringToBack();
            mapLegend.removeLegend(
                tileLayers[justDisplayedIndicator].options.legend);
        }

        tileLayers[currentlyDisplayedIndicator].bringToFront();
        mapLegend.addLegend(
            tileLayers[currentlyDisplayedIndicator].options.legend);
    }
// }); // NON-DEBUGGING VERSION



