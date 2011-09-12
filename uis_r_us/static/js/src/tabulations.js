var Sectors = (function(){
    var sectors;
    function changeKey(o, key) {
        o['_' + key] = o[key];
        delete(o[key]);
        return o;
    }
    function Sector(d){
        changeKey(d, 'subgroups');
        changeKey(d, 'columns');
        $.extend(this, d);
    }
    Sector.prototype.subGroups = function() {
        return this._subgroups;
    }
    function init(_sectors) {
        sectors = _(_sectors).chain()
                        .clone()
                        .map(function(s){return new Sector(s);})
                        .value();
        return true;
    }
    function clear() {
        sectors = [];
    }
    function pluck(slug) {
        return _(sectors).chain()
                .filter(function(s){return s.slug == slug;})
                .first()
                .value();
    }
    function all() {
        return sectors;
    }
    return {
        init: init,
        pluck: pluck,
        all: all,
        clear: clear
    };
})();

var Tabulation = (function(){
    function init () {
        return true;
    }
    function filterBySector (sector) {
        return _.filter(Data.data(), function(d){
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
    };
})();

var Data = (function(){
    var data;
    function init(_data, _sectors) {
        data = _data;
        Sectors.init(_sectors);
        return true;
    }
    function clear() {
        data = [];
        Sectors.clear();
    }
    return {
        Sectors: Sectors,
        Tabulation: Tabulation,
        data: function(){return data;},
        init: init,
        clear: clear
    }
})();