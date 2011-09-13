var debugMode = true;

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
    Sector.prototype.getColumns = function() {
        function displayOrderSort(a,b) { return (a.display_order > b.display_order) ? 1 : -1 }
        return this._columns.sort(displayOrderSort);
    }
    function init(_sectors) {
        sectors = _(_sectors).chain()
                        .clone()
                        .map(function(s){return new Sector(_.extend({}, s));})
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
    function validate() {
        if(!sectors instanceof Array)
            warn("Sectors must be defined as an array");
        if(sectors.length===0)
            warn("Sectors array is empty");
        _.each(sectors, function(sector){
            if(sector.name === undefined) { warn("Sector name must be defined."); }
            if(sector.slug === undefined) { warn("Sector slug must be defined."); }
        });
        var slugs = _(sectors).pluck('slug');
        if(slugs.length !== _(slugs).uniq().length) {
            warn("Sector slugs must not be reused");
        }
        // $(this.columns).each(function(i, val){
        //   var name = val.name;
        //   var slug = val.slug;
        //   name === undefined && warn("Each column needs a slug", this);
        //   slug === undefined && warn("Each column needs a name", this);
        // });
        return true;
    }
    function slugs() {
        return _.pluck(sectors, 'slug');
    }
    return {
        init: init,
        pluck: pluck,
        slugs: slugs,
        all: all,
        validate: validate,
        clear: clear
    };
})();

var Tabulation = (function(){
    function init () {
        return true;
    }
    function filterBySector (sector) {
        return _.filter(NMIS.data(), function(d){
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

var FacilityTables = (function(){
    function createForSector(s) {
        var tbody = $('<tbody />');
        var sector = Sectors.pluck(s);
        var div = $('<div />');
        var cols = sector.getColumns().sort(function(a,b){return a.display_order-b.display_order;});
        div.append(_createNavigation(sector));

        var orderedFacilities = NMIS.dataForSector(sector.slug);
        _.each(orderedFacilities, function(facility, i){
            _createRow(facility, cols)
                .appendTo(tbody);
        });
        div.append($('<table />')
                        .append(_createHeadRow(sector, cols))
                        .append(tbody));
        return div;
    }
    function _createRow(facility, cols) {
        var tr = $('<tr />');
        _.each(cols, function(col, i){
            $('<td />').text(i)
                .appendTo(tr);
        })
        return tr;
    }
    function _createNavigation(sector) {
        var p = $('<p />');
        var subgroups = sector.subGroups(),
            sgl = subgroups.length;
        _.each(subgroups, function(sg, i){
            $('<a />', {href: '#'})
                .text(sg.name)
                .addClass('sub-sector-link-'+sg.slug)
                .appendTo(p);
            if(i < sgl - 1)
                $('<span />').text(' | ').appendTo(p);
        });
        return p;
    }
    function _createHeadRow(sector, cols) {
        var tr = $('<tr />');
        _.each(cols, function(col, i){
            $('<th />').text(col.name)
                .appendTo(tr);
        });
        return tr;
    }
    return {
        createForSector: createForSector
    };
})();

var NMIS = (function(){
    var data;
    function init(_data, _sectors) {
        data = _.clone(_data);
        Sectors.init(_sectors);
        return true;
    }
    function clear() {
        data = [];
        Sectors.clear();
    }
    function ensureUniqueId(datum) {
        if(datum._uid === undefined) {
            datum._uid = _.uniqueId('fp');
        }
    }
    function ensureLatLng(datum) {
        if(datum._latlng === undefined && datum.gps !== undefined) {
            var llArr = datum.gps.split(' ');
            datum._latlng = [ llArr[0], llArr[1] ];
        }
    }
    function validateData() {
        Sectors.validate();
        _(data).each(ensureUniqueId);
        _(data).each(ensureLatLng);
        return true;
    }
    function dataForSector(sectorSlug) {
        var sector = Sectors.pluck(sectorSlug);
        return _(data).filter(function(datum){
            return datum.sector == sector.slug;
        });
    }
    return {
        Sectors: Sectors,
        Tabulation: Tabulation,
        data: function(){return data;},
        dataForSector: dataForSector,
        validateData: validateData,
        FacilityTables: FacilityTables,
        init: init,
        clear: clear
    }
})();