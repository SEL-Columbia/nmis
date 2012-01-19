$('.page-header').remove();

/*
//NMIS.DisplayWindow.showTitle('tables')
*/
NMIS.DisplayWindow.init(".content", {
    offsetElems: '.topbar .fill .container',
    sizeCookie: true,
    callbacks: {
        resize: [
            function(animate, sizeName){
                NMIS.SectorDataTable.resizeColumns();
                if(sizeName==="full") {
                    NMIS.DisplayWindow.showTitle('tables');
                    // temporarily setting to 400. figure out correct size later.
                    NMIS.SectorDataTable.updateScrollSize(400);
                } else if(sizeName==="middle") {
                    NMIS.SectorDataTable.updateScrollSize(120);
                    _.delay(function(){
                        NMIS.DisplayWindow.showTitle('bar');
                    }, 300);
                } else if(sizeName==="minimized") {
                    NMIS.DisplayWindow.showTitle('bar');
                }
            }
        ]
    }
});

var overviewObj = {
    name: 'Overview', slug: 'overview'
};

NMIS.loadSectors(sectorData, {
    'default': {
        name: 'Overview', slug: 'overview'
    }
});

NMIS.init();

var wElems = NMIS.DisplayWindow.getElems();

/*
initializing a Sammy.js object, called "dashboard".
This will route URLs and handle links to pre-routed URLs.

routes are defined in nmis_facilities.js and nmis_summary.js by:
    dashboard.get("/url/:variable", callback);

URL actions can be triggered by calling:
    dashboard.setLocation("/url/hello");
*/
var dashboard = $.sammy('body', function(){
    this.get("/nmis~/:state/:lga/?", function(){
        // when user lands at this base page, they will
        // be redirected to a default section (ie. "summary")
        var defaultUrl = "/nmis~/" + this.params.state +
                        "/" + this.params.lga +
                        "/summary/";
        dashboard.setLocation(defaultUrl);
    });
});

/*
NMIS.LocalNav is the navigation element at the top of the page.
URLs are rebuilt as the user navigates through the page.
*/
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
	NMIS.urlFor = function(_o){
        var o = _.extend({
            //defaults
            root: '/nmis~',
            mode: 'summary'
        }, _o);
        if(!o.lga || !o.state) return "/nmis~?error";
        var uu = (function _pushAsDefined(obj, keyList) {
    	    var key, i, l, arr = [], item;
    	    for(i=0, l=keyList.length; i < l; i++) {
    	        key = keyList[i];
    	        item = obj[key];
                if(!!item) {
                    if(item===false) { return ["/error"]; }
                    arr.push(item.slug === undefined ? item : item.slug);
    	        } else {
    	            return arr;
    	        }
    	    }
    	    return arr;
    	})(o, ["root", "state", "lga", "mode",
                        "sector", "subsector", "indicator"]).join('/');
        if(!!o.facilityId) {
            uu += "?facility="+o.facilityId;
        }
        return uu;
    }
    $('.url-for').each(function(){
        var d = $(this).data('urlFor');
        $(this).attr('href', NMIS.urlFor(_.extend({
            lga: lga.slug,
            state: state.slug
        }, d)));
    });
    var env = {root: '/nmis~', state: state, lga: lga};
    NMIS.Breadcrumb.init("p.bc", {
        levels: [
            [state.name, env.root],
            [lga.name, "/nmis~/"+state.slug+"/"+lga.slug+"/"]
        ]
    });
})();
