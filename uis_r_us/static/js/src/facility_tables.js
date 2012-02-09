var DisplayValue = (function(){
    function roundDown(v, i) {
    	var c = 2;
    	var d = Math.pow(10, c);
    	return Math.floor(v * d) / d;
    }
    function Value(v) {
        if(v===undefined) {
            return ["&mdash;", 'val-undefined'];
    	} else if (v===null) {
            return ["null", 'val-null'];
        } else if (v===true) {
    	    return ["Yes"];
    	} else if (v===false) {
    	    return ["No"];
    	} else if (!isNaN(+v)) {
    	    return [roundDown(v)];
    	}
        return [v];
    }
    function DisplayInElement(d, td) {
        var res = Value(d);
        if (d[1]!==undefined) td.addClass(res[1]);
        return td.html(res[0]);
    }
    DisplayInElement.raw = Value;
    DisplayInElement.special = function(v, indicator) {
        var r = Value(v),
            o = {name: indicator.name, classes: "", value: r[0]};
        if(indicator.display_style==="checkmark_true") {
            o.classes = "label ";
            if(v===true) {
                o.classes += "chk-yes";
            } else if(v===false) {
                o.classes += "chk-no";
            } else {
                o.classes += "chk-null";
            }
        } else if(indicator.display_style==="checkmark_false") {
            o.classes = "label ";
            if(v===true) {
                o.classes += "chk-no";
            } else if(v===false) {
                o.classes += "chk-yes";
            } else {
                o.classes += "chk-null";
            }
        }
        return o;
    }
    return DisplayInElement;
})();

var SectorDataTable = (function(){
    var dt, table;
    function dtOpts(_o) {
        return _.extend({
            sScrollY: 120,
            bScrollCollapse: false,
            bPaginate: false
        }, _o);
    }
    var tableSwitcher;
    function createIn(tableWrap, env, _opts) {
        var opts = _.extend({
            sScrollY: 120
        }, _opts);
        var data = NMIS.dataForSector(env.sector.slug);
        if(env.subsector===undefined) {
            throw(new Error("Subsector is undefined"));
        }
        env.subsector = env.sector.getSubsector(env.subsector.slug);
        var columns = env.subsector.columns();

        if(tableSwitcher) {tableSwitcher.remove();}
        tableSwitcher = $('<select />');
        _.each(env.sector.subGroups(), function(sg){
            $('<option />').val(sg.slug).text(sg.name).appendTo(tableSwitcher);
        });
        tableSwitcher
                    .val(env.subsector.slug)
                    .appendTo(tableWrap)
                    .change(function(){
                        var ssSlug = $(this).val();
                        var nextUrl = NMIS.urlFor(_.extend({},
                                        env,
                                        {subsector: env.sector.getSubsector(ssSlug)}));
                        dashboard.setLocation(nextUrl);
                    });
        table = $('<table />')
            .addClass('bs')
            .append(_createThead(columns))
            .append(_createTbody(columns, data));
        tableWrap.append(table);
        dt = table.dataTable(dtOpts({
            "sDom": "<'row'<'span8'l><'span8'f>r>t<'row'<'span8'i><'span8'p>>",
            sScrollY: opts.sScrollY
        }));
		table.delegate('tr', 'click', function(){
		    log($(this).data('rowData'));
		});
        return table;
    }
    function updateScrollSize(ss) {
        if(!!table) {
            dt = table.dataTable(dtOpts({
                sScrollY: ss,
                bDestroy: true
            }));
        }
    }
    function handleHeadRowClick() {
        var column = $(this).data('column');
        var indicatorSlug = column.slug;
        if(!!indicatorSlug) {
            var newEnv = _.extend({}, NMIS.Env(), {
                indicator: indicatorSlug
            });
            if(!newEnv.subsector) {
                newEnv.subsector = _.first(newEnv.sector.subGroups());
            }
            var newUrl = NMIS.urlFor(newEnv);
            dashboard.setLocation(newUrl);
        }
    }
    function _createThead(cols) {
        var row = $('<tr />');
        _.each(cols, function(col){
            row.append($('<th />').text(col.name).data('column', col));
        });
        row.delegate('th', 'click', handleHeadRowClick);
        return $('<thead />').html(row);
    }
    function nullMarker() {
        return $('<span />').html('&mdash;').addClass('null-marker');
    }
    function resizeColumns() {
        if(!!dt) dt.fnAdjustColumnSizing();
    }
    function _createTbody(cols, rows) {
        var tbody = $('<tbody />');
        _.each(rows, function(r){
            var row = $('<tr />').data("row-data", r._id);
            _.each(cols, function(c){
                // quick fixes in this function scope will need to be redone.
                var z = r[c.slug] || nullMarker();
                var td = $('<td />');
                /*--
                TODO: get some way in the table_defs to specify how a column should be formatted
                if(c.needs_formatting?) {
                --*/
                if($.type(z)==="number") {
                    z = Math.floor(+z*100)/100;
                } else {
                    z = NMIS.HackCaps(z);
                }
                td.html(z);
                row.append(td);
            });
            tbody.append(row);
        });
        return tbody;
    }
    return {
        createIn: createIn,
        updateScrollSize: updateScrollSize,
        resizeColumns: resizeColumns
    }
})();

var FacilityTables = (function(){
    var div;
    function createForSectors(sArr, _opts) {
        var opts = _.extend({
            //default options
            callback: function(){},
            sectorCallback: function(){},
            indicatorClickCallback: function(){}
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
            sectorNav.find('.sub-sector-link-' + subsector.slug)
                .addClass('active')
        }
        div.find('td, th').hide();
        var sectorElem = div.find('.facility-display').filter(function(){
            return $(this).data('sector') === sector.slug;
        }).eq(0);
        sectorElem.find('.subgroup-all, .subgroup-'+subsector.slug).show();
    }
    function createForSector(s, opts) {
        var tbody = $('<tbody />');
        var sector = NMIS.Sectors.pluck(s);
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
        $('<table />')
            .append(_createHeadRow(sector, cols, opts))
            .append(tbody)
            .appendTo(iDiv);
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
                .addClass('sub-sector-link')
                .addClass('sub-sector-link-'+sg.slug)
                .appendTo(sectorNav);
            if(i < sgl - 1)
                $('<span />').text(' | ').appendTo(sectorNav);
        });
        return sectorNav;
    }
    function classesStr(col) {
        var clss = ['data-cell'];
        _.each(col.subgroups, function(sg){
            clss.push('subgroup-'+sg);
        });
        return clss.join(' ');
    }
    function hasClickAction(col, carr) {
    	return !!(!!col.click_actions && col.click_actions.indexOf(col));
    }
    function _createHeadRow(sector, cols, opts) {
        var tr = $('<tr />');
        _.each(cols, function(col, i){
	    var th = $('<th />', {'class': classesStr(col)})
	        .data('col', col);
	    if (!!col.clickable) {
    		th.html($('<a />', {href: '#'}).text(col.name).data('col',col));
	    } else {
    		th.text(col.name);
	    }
	    th.appendTo(tr);
        });
        tr.delegate('a', 'click', function(evt){
            opts.indicatorClickCallback.call($(this).data('col'));
            return false;
        });
        return $('<thead />').html(tr);
    }
    function highlightColumn(column, _opts) {
        // var opts = _.extend({
        //     highlightClass: 'fuchsia'
        // }, _opts);
        div.find('.highlighted').removeClass('highlighted');
        var th = div.find('th').filter(function(){
            return ($(this).data('col').slug === column.slug)
        }).eq(0);
        var table = th.parents('table').eq(0);
        var ind = th.index();
        table.find('tr').each(function(){
            $(this).children().eq(ind).addClass('highlighted');
        });
//        log(column, '.subgroup-'+column.slug, );
    }
    return {
        createForSectors: createForSectors,
        highlightColumn: highlightColumn,
        select: select
    };
})();

if("undefined" !== typeof NMIS) {
    NMIS.SectorDataTable = SectorDataTable;
    NMIS.FacilityTables = FacilityTables;
} else {
    $(function(){
        if(NMIS) {
            NMIS.SectorDataTable = SectorDataTable;
            NMIS.FacilityTables = FacilityTables;
        }
    });
}
