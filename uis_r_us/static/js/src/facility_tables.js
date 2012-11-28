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
    	} else if ($.type(v) === "string") {
    	    return [NMIS.HackCaps(v)]
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
    DisplayInElement.inTdElem = function(facility, indicator, elem) {
        var vv = facility[indicator.slug],
            c = Value(vv);
        var chkY = indicator.display_style === "checkmark_true",
            chkN = indicator.display_style === "checkmark_false";

        if(chkY || chkN) {
            var oclasses = "label ";
            if($.type(vv)==="boolean") {
                if(vv) {
                    oclasses += chkY ? "chk-yes" : "chk-no";
                } else {
                    oclasses += chkY ? "chk-no" : "chk-yes";
                }
            } else {
                oclasses += "chk-null";
            }
            c[0] = $('<span />').addClass(oclasses).html(c[0]);
        }
        return elem.html(c[0]);
    }

    return DisplayInElement;
})();

var SectorDataTable = (function(){
    var dt, table;
    var tableSwitcher;
    var dataTableDraw = function(){};
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
        table = $('<table />')
            .addClass('facility-dt')
            .append(_createThead(columns))
            .append(_createTbody(columns, data));
        tableWrap.append(table);
        dataTableDraw = function(s){
            dt = table.dataTable({
                sScrollY: s,
                bDestroy: true,
                bScrollCollapse: false,
                bPaginate: false,
                fnDrawCallback: function() {
                    var newSelectDiv, ts;
                    $('.dataTables_info', tableWrap).remove();
                    if($('.dtSelect', tableWrap).get(0)===undefined) {
                        ts = getSelect();
                        newSelectDiv = $('<div />', {'class': 'dataTables_filter dtSelect left'})
                                            .html($('<p />').text("Grouping:").append(ts));
                        $('.dataTables_filter', tableWrap).parents().eq(0)
                                .prepend(newSelectDiv);
                        ts.val(env.subsector.slug);
                        ts.change(function(){
                            var ssSlug = $(this).val();
                            var nextUrl = NMIS.urlFor(_.extend({},
                                            env,
                                            {subsector: env.sector.getSubsector(ssSlug)}));
                            dashboard.setLocation(nextUrl);
                        });
                    }
                }
            });
            return tableWrap;
        }
        dataTableDraw(opts.sScrollY);
        table.delegate('tr', 'click', function(){
            dashboard.setLocation(NMIS.urlFor(_.extend({}, NMIS.Env(), {facilityId: $(this).data('rowData')})));
        });
        return table;
    }
    function getSelect() {
        return tableSwitcher.clone();
    }
    function setDtMaxHeight(ss) {
        var tw, h1, h2;
        tw = dataTableDraw(ss);
        // console.group("heights");
        // log("DEST: ", ss);
        h1 = $('.dataTables_scrollHead', tw).height();
        // log(".dataTables_scrollHead: ", h);
        h2 = $('.dataTables_filter', tw).height();
        // log(".dataTables_filter: ", h2);
        ss = ss - (h1 + h2);
        // log("sScrollY: ", ss);
        dataTableDraw(ss);
        // log(".dataTables_wrapper: ", $('.dataTables_wrapper').height());
        // console.groupEnd();
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
        var startsWithType = cols[0].name=="Type";
        _.each(cols, function(col, ii){
            if(ii===1 && !startsWithType) {
                $('<th />').text('Type').appendTo(row);
            }
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
            var row = $('<tr />');
            if (r._id === undefined) {
              console.error("Facility does not have '_id' defined:", r);
            } else {
              row.data("row-data", r._id);
            }
            var startsWithType = cols[0].name=="Type";
            _.each(cols, function(c, ii){
                // quick fixes in this function scope will need to be redone.
                if(ii===1 && !startsWithType) {
                    var ftype = r.facility_type || r.education_type || r.water_source_type || "unk";
                    $('<td />').attr('title', ftype).addClass('type-icon').html($('<span />').addClass('icon').addClass(ftype).html($('<span />').text(ftype))).appendTo(row);
                }
                var z = r[c.slug] || nullMarker();
                var td = DisplayValue.inTdElem(r, c, $('<td />'));
                row.append(td);
            });
            tbody.append(row);
        });
        return tbody;
    }
    return {
        createIn: createIn,
        setDtMaxHeight: setDtMaxHeight,
        getSelect: getSelect,
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
