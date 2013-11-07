 $(function() {
    var map, tileLayers;
    var mapLegend, currentlyDisplayedIndicator;
    
    map = newMDGsMap();
    tileLayers = {},

    initTileLayersFromIndicatorNames(
        ['NMIS_gross_enrollment_ratio_secondary_education',
         'NMIS_percentage_households_with_access_to_improved_sanitation'],
        map);
    
    // Creates a new MDGs map (with nothing but centering information)
    function newMDGsMap() {
        //ex: NMIS_gross_enrollment_ratio_secondary_education
        var centroid = {lat: 9.16718, lng: 7.53662};
        var mapZoom = 6;
        var mapDiv = $('.mdg-map')[0];
        var map = L.map(mapDiv, {
            center: new L.LatLng(centroid.lat, centroid.lng),
            zoom: mapZoom,
        });
        L.mapbox.tileLayer('modilabs.nigeria_base').addTo(map);
        mapLegend = L.mapbox.legendControl().addTo(map);
        return map;
    }

    // Creates layer per indicatorName and  adds it to tileLayers object
    function initTileLayersFromIndicatorNames(indicatorNames, map) {
        indicatorNames.forEach(function(indicatorName) {
            var thisLayer = L.mapbox.tileLayer('modilabs.' + indicatorName);
            tileLayers[indicatorName] = thisLayer;
        });
    }

    // Change indicator layer
    window.changeIndicator = function(indicatorName) {
        var justDisplayedIndicator = currentlyDisplayedIndicator;
        currentlyDisplayedIndicator = indicatorName;

        // justDisplayedIndicator doesn't exist on first change, no removals necessary
        if (justDisplayedIndicator) {
            map.removeLayer(tileLayers[justDisplayedIndicator]);
            mapLegend.removeLegend(
                tileLayers[justDisplayedIndicator].options.legend);
        }

        tileLayers[currentlyDisplayedIndicator].addTo(map);
        mapLegend.addLegend(
            tileLayers[currentlyDisplayedIndicator].options.legend);
    }
});



