var Tabulation = (function(){
    var data;
    function init (_data) {
        data = _data;
        return true;
    }
    function ensureData() {
        if(data===undefined) {
            warn("Data is undefined");
        }
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
        var values = _(filterBySector(sector)).chain()
                        .pluck(slug)
                        .map(function(v){
                            return '' + v;
                        })
                        .value();
        if(keys===undefined) keys = _.uniq(values).sort();
        _.each(keys, function(key) { occurrences[key] = 0; });
        _.each(values, function(d){
            if(occurrences[d] !== undefined)
                occurrences[d]++;
        });
        return occurrences;
    }
    function sectorSlugAsArray (sector, slug, keys) {
        var occurrences = sectorSlug.apply(this, arguments);
        if(keys===undefined) { keys = _.keys(occurrences).sort(); }
        return _(keys).map(function(key){
            return {
                occurrences: '' + key,
                value: occurrences[key]
            };
        });
    }
    return {
        init: init,
        sectorSlug: sectorSlug,
        sectorSlugAsArray: sectorSlugAsArray,
        bySector: bySector
    };
})();