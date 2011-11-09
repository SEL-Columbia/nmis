var DisplayValue = (function(){
    function roundDown(v, i) {
	var c = 2;
	var d = Math.pow(10, c);
	return Math.floor(v * d) / d;
    }
    function Value(v, td) {
        if(v===undefined) {
            return td.html("&mdash;").addClass('val-undefined');
	} else if (v===null) {
            return td.html("null").addClass('val-null');
        } else if (v===true) {
	    return td.html("Yes");
	} else if (v===false) {
	    return td.html("No");
	} else if (!isNaN(+v)) {
	    return td.html(roundDown(v));
	}
        return td.html(v);
    }
    return function(d, td){
	return Value(d, td);
    };
})();

var FacilityTables = (function(){
    var div;
    function createForSectors(sArr, _opts) {
        var opts = _.extend({
            //default options
            callback: function(){},
            sectorCallback: function(){}
        }, _opts);
        if(div===undefined) {
            div = $('<div />').addClass('facility-display-wrap');
        }
        div.empty();
        _.each(sArr, function(s){
            div.append(createForSector(s, opts));
        });
        if(opts.callback) {
            opts.callback.call(this, div);
        }
        return div;
    }
    function select(sector, subsector) {
        if(sectorNav!==undefined) {
            sectorNav.find('a.active').removeClass('active');
            sectorNav.find('.sub-sector-link-' + subsector)
                .addClass('active')
        }
        div.find('td, th').hide();
        var sectorElem = div.find('.facility-display').filter(function(){
            return $(this).data('sector') === sector;
        }).eq(0);
        sectorElem.find('.subgroup-all, .subgroup-'+subsector).show();
    }
    function createForSector(s, opts) {
        var tbody = $('<tbody />');
        var sector = Sectors.pluck(s);
        var iDiv = $('<div />')
                        .addClass('facility-display')
                        .data('sector', sector.slug);
        var cols = sector.getColumns().sort(function(a,b){return a.display_order-b.display_order;});

        var orderedFacilities = NMIS.dataForSector(sector.slug);
        var dobj = NMIS.dataObjForSector(sector.slug);
        _.each(dobj, function(facility, fid){
            _createRow(facility, cols, fid)
                .appendTo(tbody);
        });
        iDiv.append($('<table />')
            .append(_createHeadRow(sector, cols))
            .append(tbody));
        opts.sectorCallback.call(this, sector, iDiv, _createNavigation, div);
        return iDiv;
    }
    function _createRow(facility, cols, facilityId) {
        var tr = $('<tr />').data('facility-id', facilityId);
        _.each(cols, function(col, i){
            var slug = col.slug;
            var rawval = facility[slug];
            var val = DisplayValue(rawval, $('<td />', {'class': classesStr(col)})).appendTo(tr);
        });
        return tr;
    }
    var sectorNav;
    function _createNavigation(sector, _hrefCb) {
        sectorNav = $('<p />').addClass('facility-sectors-navigation');
        var subgroups = sector.subGroups(),
            sgl = subgroups.length;
        _.each(subgroups, function(sg, i){
            var href = _hrefCb(sg);
            $('<a />', {href: href})
                .text(sg.name)
                .data('subsector', sg.slug)
                .addClass('sub-sector-link-'+sg.slug)
                .appendTo(sectorNav);
            if(i < sgl - 1)
                $('<span />').text(' | ').appendTo(sectorNav);
        });
        return sectorNav;
    }
    function classesStr(col) {
	var clss = ['data-cell']
        _.each(col.subgroups, function(sg){
            clss.push('subgroup-'+sg)
        });
	return clss.join(' ');
    }
    function hasClickAction(col, carr) {
	return !!(!!col.click_actions && col.click_actions.indexOf(col));
    }
    function _createHeadRow(sector, cols) {
        var tr = $('<tr />');
        _.each(cols, function(col, i){
	    var th = $('<th />', {'class': classesStr(col)});
	    if (hasClickAction(col, 'piechart_false') || hasClickAction(col, 'piechart_true')) {
		th.html($('<a />', {href:'#'}).text(col.name).data('col',col));
	    } else {
		th.text(col.name);
	    }
	    th.appendTo(tr);
        });
        return tr;
    }
    return {
        createForSectors: createForSectors,
        select: select
    };
})();
