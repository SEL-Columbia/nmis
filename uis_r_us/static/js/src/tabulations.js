var Tabulation = (function(){
    var data;
    function init (_data) {
        data = _data;
        return true;
    }
    function bySector (sector) {
        return _.map(data, function(d){
            return 3;
        });
    }
    // function byAttributes(atts) {
    //     return _.map(data, function(){});
    // }
    function filterBySector (sector) {
        return _.filter(data, function(d){
            return d.sector == sector;
        })
    }
    function sectorSlug (sector, slug, keys) {
        var occurrences = {};
        var values = _.pluck(filterBySector(sector), slug);
        if(keys===undefined) keys = _.uniq(values);
        _.each(keys, function(key) { occurrences[key] = 0; });
        _.each(values, function(d){
            if(occurrences[d] !== undefined)
                occurrences[d]++;
        });
        return JSON.stringify(occurrences)
    }
    return {
        init: init,
        sectorSlug: sectorSlug,
        bySector: bySector
    };
})();