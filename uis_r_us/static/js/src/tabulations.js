var debugMode = true;

var Breadcrumb = (function(){
    var levels = [];
    var elem;
    var context = {};

    function init(_elem, _opts) {
        elem = $(_elem).eq(0);
        var opts = _.extend({
            draw: true
        }, _opts);
        levels = _.extend(levels, (opts.levels || []));
        if(!!opts.draw) {
            draw();
        }
    }
    function clear() {
        if (elem !== undefined) {
            elem.empty();
        }
        levels = [];
    }
    function setLevels(_levels) {
        levels = _.extend(levels, (_levels || []));
        draw();
        return context;
    }
    function setLevel(ln, d) {
        levels[ln] = d;
        return context;
    }
    function draw() {
        if (elem !== undefined) {
            elem.empty();
        }
        var a;
        _.each(levels, function(level, i){
            if(i!==0) {
                $('<span />')
                    .text('/')
                    .appendTo(elem);
            }
            a = $('<a />')
                .text(level[0])
                .attr('href', level[1]);
            if(level.length > 2) { a.click(level[2]); }
            a.appendTo(elem);
        });
    }
    return {
        init: init,
        setLevels: setLevels,
        setLevel: setLevel,
        draw: draw,
        _levels: function(){return levels;},
        clear: clear
    }
})();

var MapMgr = (function(){
    var opts,
        started = false,
        callbackStr = "MapMgr.loaded";
    function init(_opts) {
        if(started) {
            return;
        }
        opts = _.extend({
            //defaults
            launch: true,
            fake: false,
            fakeDelay: 3000,
            elem: 'body',
            defaultMapType: 'SATELLITE',
            loadCallbacks: []
        }, _opts);
        if(!opts.ll) {
            if(opts.llString) {
                var t = opts.llString.split(' ');
                opts.ll = {
                    lat: +t[0],
                    lng: +t[1]
                };
            }
        }
        started = true;
        opts.elem = $(opts.elem);
        if(opts.launch) {
            $.getScript('http://maps.googleapis.com/maps/api/js?sensor=false&callback='+callbackStr);
        } else if(opts.fake) {
            _.delay(loaded, opts.fakeDelay);
        }
    }
    function loaded() {
        _.each(opts.loadCallbacks, function(cb){
            cb.call(opts);
        });
    }
    function addLoadCallback(cb) {
        opts.loadCallbacks.push(cb);
    }
    return {
        init: init,
        loaded: loaded,
        addLoadCallback: addLoadCallback
    }
})();

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


var DataLoader = (function(){
    function fetch(url){
        return $.getJSON(url);
    }
    return {
        fetch: fetch
    };
})();


var DisplayWindow = (function(){
    var elem, elem1, elem0, elem1content;
    var fullHeight;
    var opts;
    var visible;
    var hbuttons;
    var titleElems = {};
    var curSize;
    function init(_elem, _opts) {
        if(opts !== undefined) { clear(); }
        elem = $(_elem);
        opts = _.extend({
            //default options:
            height: 100,
            clickSizes: [
                ['full', 'Hide Map'],
                ['middle', 'Split'],
                ['minimized', 'Hide Table']
            ],
            size: 'full',
            sizeCookie: false,
            callbacks: {},
            visible: false,
            heights: {
                full: Infinity,
                middle: 280,
                minimized: 46
            },
            allowHide: true,
            fullResizer: true,
            padding: 45
        }, _opts);
        elem0 = $('<div />')
            .appendTo(elem);
        elem1 = $('<div />')
            .appendTo(elem);
        visible = !!opts.visible;
        setVisibility(visible, false);
        if(opts.sizeCookie) {
            opts.size = $.cookie("displayWindowSize") || opts.size;
        }

        if(opts.fullResizer) {
            var oh = 0;
            $(opts.offsetElems).each(function(){ oh += $(this).height(); });
            fullHeight = $(window).height() - oh - opts.padding;
            elem.height(fullHeight);
            elem.addClass('display-window-wrap');
            elem0.height(fullHeight);
            elem1.addClass('display-window-content');
        }
        createHeaderBar()
            .appendTo(elem1);
        elem1content = $('<div />')
            .appendTo(elem1);
        setSize(opts.size);
    }
    function setTitle(t) {
        _.each(titleElems, function(e){
            e.text(t);
        });
    }
    var curTitle;
    function showTitle(i) {
        curTitle = i;
        _.each(titleElems, function(e, key){
            if(key===i) {
                e.show();
            } else {
                e.hide();
            }
        });
    }
    function addCallback(cbname, cb) {
        if(opts.callbacks[cbname]===undefined) {
            opts.callbacks[cbname] = [];
        }
        opts.callbacks[cbname].push(cb);
    }
    function setBarHeight(h, animate) {
        if(animate) {
            elem1.animate({
                height: h
            }, 200);
        } else {
            elem1.css({
                height: h
            });
        }
    }
    var prevSize, sizeTempSet = false;
    function setTempSize(size, animate) {
        prevSize = curSize;
        sizeTempSet = true;
        setSize(size, animate);
    }
    function unsetTempSize(animate) {
        if(sizeTempSet) {
            setSize(prevSize, animate);
            prevSize = undefined;
            sizeTempSet = false;
        }
    }
    function setSize(_size, animate) {
        var size;
        if(opts.heights[_size] !== undefined) {
            size = opts.heights[_size];
            if(size === Infinity) {
                size = fullHeight;
            }
            $.cookie("displayWindowSize", _size);
            setBarHeight(size, animate);
            curSize = _size;
        }
        if(opts.callbacks[_size] !== undefined) {
            _.each(opts.callbacks[_size], function(cb){
                cb(animate);
            });
        }
        if(opts.callbacks.resize !== undefined) {
            _.each(opts.callbacks.resize, function(cb){
                cb(animate, _size, elem, elem1, elem1content);
            });
        }
        hbuttons.find('.primary')
            .removeClass('primary');
        hbuttons.find('.clicksize.'+_size)
            .addClass('primary');
    }
    function setVisibility(tf) {
        var css = {};
        if(!tf) {
            css = {'left': '1000em'};
        } else {
            css = {'left': '0'};
        }
        elem0.css(css);
        elem1.css(css);
    }
    function addTitle(key, jqElem) {
        titleElems[key] = jqElem;
        if(curTitle===key) {
            showTitle(key);
        }
    }
    function createHeaderBar() {
        hbuttons = $('<span />'); //.addClass('print-hide-inline');
        _.each(opts.clickSizes, function(sizeArr){
            var size = sizeArr[0],
                desc = sizeArr[1];
            $('<a />')
                .attr('class', 'btn small clicksize ' + size)
                .text(desc)
                .attr('title', desc)
                .click(function(){
                    setSize(size, true)
                })
                .appendTo(hbuttons);
        });
        titleElems.bar = $('<h3 />').addClass('bar-title').hide();
        return $('<div />', {'class': 'display-window-bar breadcrumb'})
            .css({'margin':0})
            .append(titleElems.bar)
            .append(hbuttons);
    }
    function clear(){
        elem !== undefined && elem.empty();
        titleElems = {};
    }
    function getElems() {
        return {
            wrap: elem,
            elem0: elem0,
            elem1: elem1,
            elem1content: elem1content
        }
    }
    function elem1contentHeight() {
        var padding = 30;
        return elem1.height() - hbuttons.height() - padding;
    }
    return {
        init: init,
        clear: clear,
        setSize: setSize,
        setTempSize: setTempSize,
        setVisibility: setVisibility,
        unsetTempSize: unsetTempSize,
        addCallback: addCallback,
        addTitle: addTitle,
        setTitle: setTitle,
        showTitle: showTitle,
        elem1contentHeight: elem1contentHeight,
        getElems: getElems
    };
})();

var IconSwitcher = (function(){
    var context = {};
    var callbacks = ["createMapItem",
                        "shiftMapItemStatus",
                        "statusShiftDone",
                        "hideMapItem",
                        "showMapItem",
                        "setMapItemVisibility"];
    function init(_opts) {
        var noop = function(){};
        context = _.extend({
            items: {}
        }, _opts);
        _.each(callbacks, function(cbname){
            if(context[cbname]===undefined) { context[cbname] = noop; }
        });
    }
    function hideItem(item) {
        item.hidden = true;
    }
    function showItem(item) {
        item.hidden = false;
    }
    function setVisibility(item, tf) {
        if(!!tf) {
            if(!item.hidden) {
                item.hidden = true;
                context.setMapItemVisibility.call(item, false, item, context.items);
                return true;
            }
        } else {
            if(!!item.hidden) {
                item.hidden = false;
                context.setMapItemVisibility.call(item, true, item, context.items);
                return true;
            }
        }
        return false;
    }
    function iterate(cb) { _.each(context.items, cb); }
    function shiftStatus(fn) {
        iterate(function(item, id){
            var status = fn.call(item, id, item, context.items);
            var visChange = setVisibility(item, status === false),
                statusChange = false;
            if(status === undefined) {
                //do nothing
            } else if(status === false) {
                item.status = undefined;
            } else if(item.status !== status) {
                item.status = status;
                statusChange = true;
            }
            if(statusChange || visChange) {
                context.shiftMapItemStatus(item, id);
            }
        });
        context.statusShiftDone();
    }
    function all() { return _.values(context.items); }
    function setCallback(cbName, cb) {
        if(callbacks.indexOf(cbName) !== -1) {
            context[cbName] = cb;
        }
    }
    function filterStatus(status) {
        return _.filter(context.items, function(item){ return item.status === status; });
    }
    function filterStatusNot(status) {
        return _.filter(context.items, function(item){ return item.status !== status; });
    }
    function allShowing() {
        return filterStatusNot(undefined);
    }
    function clear() {
        context = {};
    }
    return {
        init: init,
        clear: clear,
        allShowing: allShowing,
        filterStatus: filterStatus,
        filterStatusNot: filterStatusNot,
        all: all,
        setCallback: setCallback,
        shiftStatus: shiftStatus,
        iterate: iterate
    }
})();

var LocalNav = (function(){
    var elem, wrap, opts;
    var buttonSections = {};
    var submenu;
    function init(selector, _opts) {
        wrap = $(selector);
        opts = _.extend({
            sections: []
        }, _opts);
        elem = $('<ul />', {'id': 'local-nav', 'class': 'nav'});
        wrap = $('<div />', {'class': 'row'})
                .css({'position':'absolute','top':82,'left':0,'z-index':99})
                .html(elem);
        $('.content').eq(0).prepend(wrap);
        _.each(opts.sections, function(section, i){
            if(i!==0) {
                $("<li />", {'class': 'small spacer'})
                    .html('&nbsp;')
                    .appendTo(elem);
            }
            _.each(section, function(arr){
                var code = arr[0].split(":");
                if(buttonSections[code[0]]===undefined) {buttonSections[code[0]] = {};}
                var a = $('<a />', {'href':arr[2], 'text': arr[1]});
                buttonSections[code[0]][code[1]] = a;
                $('<li />').html(a)
                    .appendTo(elem);
            });
        });
        submenu = $('<ul />')
            .addClass('submenu')
//            .html($("<li />").html($("<a />", {'href':'#', 'text':'xxx'})))
//            .css({'position':'absolute','left':400,top:38})
            .appendTo(elem);
    }
    function getNavLink(code) {
        var _x = code.split(":"),
            section = _x[0],
            name = _x[1];
        return buttonSections[section][name];
    }
    function markActive(codesArray) {
        wrap.find('.active').removeClass('active');
        _.each(codesArray, function(code){
            getNavLink(code).parents('li').eq(0).addClass('active')
        });
    }
    function clear() {
        wrap.empty();
        wrap = undefined;
        elem = undefined;
        buttonSections = {};
        submenu = undefined;
    }
    function hideSubmenu() {
        submenu.hide();
    }
    function displaySubmenu(nlcode, a, _opts) {
        var navLink = getNavLink(nlcode);
        var lpos = navLink.parents('li').eq(0).position().left;
        submenu.hide()
                .empty()
                .css({'left': lpos});
        _.each(a, function(aa){
            $('<li />')
                .html($('<a />', {text: aa[0], 'href': aa[1]}))
                .appendTo(submenu);
        });
        submenu.show();
    }
    function iterate(cb) {
        _.each(buttonSections, function(buttons, sectionName){
            _.each(buttons, function(button, buttonName){
                cb.apply(this, [sectionName, buttonName, button])
            });
        });
    }
    return {
        init: init,
        clear: clear,
        iterate: iterate,
        displaySubmenu: displaySubmenu,
        hideSubmenu: hideSubmenu,
        markActive: markActive
    }
})();

var NMIS = (function(){
    var data;
    function init(_data) {
        data = _.clone(_data);
	_(data).each(parseLatLng);
//        Sectors.init(_sectors);
        return true;
    }
    function loadSectors(_sectors){
        Sectors.init(_sectors);
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
    function parseLatLng(datum) {
	if(datum.gps===undefined) {
	    datum._ll = false;
	} else {
	    var ll = datum.gps.split(' ');
	    datum._ll = [ll[0], ll[1]];
	}
    }
    function dataForSector(sectorSlug) {
        var sector = Sectors.pluck(sectorSlug);
        return _(data).filter(function(datum, id){
            return datum.sector.toLowerCase() == sector.slug.toLowerCase();
        });
    }
    function dataObjForSector(sectorSlug) {
        var sector = Sectors.pluck(sectorSlug);
        var o = {};
        _(data).each(function(datum, id){
            if(datum.sector.toLowerCase() == sector.slug.toLowerCase()) {
                o[id] = datum;
            }
        });
        return o;
    }
    return {
        Sectors: Sectors,
        Tabulation: Tabulation,
        IconSwitcher: IconSwitcher,
        LocalNav: LocalNav,
        Breadcrumb: Breadcrumb,
        DisplayWindow: DisplayWindow,
        DataLoader: DataLoader,
        data: function(){return data;},
        dataForSector: dataForSector,
        dataObjForSector: dataObjForSector,
        validateData: validateData,
        loadSectors: loadSectors,
        init: init,
        clear: clear
    }
})();
