$('.page-header').remove();

// MapLoader will probably end up with all the other modules.
var MapLoader = (function(){
    var maploaded = false, cbs = [];
    function init(_opts) {
        log("started map load");
    }
    function loaded() {
        log("Finished map load");
        maploaded = true;
        _.each(cbs, function(cb){
            cb();
        });
    }
    function addOnload(cb) {
        if(maploaded) {
            cb();
        } else {
            cbs.push(cb);
        }
    }
    return {
        init: init,
        loaded: loaded,
        addOnload: addOnload
    }
})();

var _tIconSwitchedOn = false;
var zz = 0;
var itemStatii = {};
var itemzOnMap = {};


NMIS.DisplayWindow.init(".content", {
    offsetElems: '.topbar .fill .container',
    sizeCookie: true,
    callbacks: {
        resize: [
            function(animate, sizeName){
                if(sizeName==="full") {
                    NMIS.DisplayWindow.showTitle('tables');
                } else {
                    NMIS.DisplayWindow.showTitle('bar');
                }
            }
        ]
    }
});

var wElems = NMIS.DisplayWindow.getElems();

var dashboard = $.sammy('body');
(function(){
    NMIS.LocalNav.init(wElems.wrap, {
        sections: [
            [
                ["mode:summary", "LGA Summary", "#"],
                ["mode:facilities", "Facility Detail", "#"]
            ],
            [
                ["sector:overview", "Overview", "#"],
                ["sector:health", "Health", "#"],
                ["sector:education", "Education", "#"],
                ["sector:water", "Water", "#"]
            ]
        ]
    });

    NMIS.Breadcrumb.init("p.bc", {
        levels: [
            [state.name, "/nmis~/"],
            [lga.name, "/nmis~/"+state.slug+"/"+lga.slug+"/"]
        ]
    });

	function _pushAsDefined(obj, keyList) {
	    var key, i, l, arr = [], item;
	    for(i=0, l=keyList.length; i < l; i++) {
	        key = keyList[i];
	        item = obj[key];
            if(item !== undefined) {
                if(item===false) { return ["/error"]; }
                arr.push(item.slug === undefined ? item : item.slug);
	        } else {
	            return arr;
	        }
	    }
	}
	NMIS.urlFor = function(_o){
        var o = _.extend({
            //defaults
            root: '/nmis~',
            mode: 'summary'
        }, _o);
        if(!o.lga || !o.state) return "/error";
        return _pushAsDefined(o,
                        ["root", "state", "lga", "mode",
                        "sector", "subsector", "indicator"]).join('/');
    }
})();
