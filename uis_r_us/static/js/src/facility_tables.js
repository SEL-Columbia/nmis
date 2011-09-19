var FacilityTables = (function(){
    var div;
    function createForSectors(sArr) {
        if(div===undefined) { div = $('<div />');
        } else { div.empty();
        }
        _.each(sArr, function(s){
            div.append(createForSector(s));
        });
        return div;
    }
    function select(sector, subsector) {
        div.find('td, th').hide();
        var sectorElem = div.find('.facility-display').filter(function(){
            return $(this).data('sector')==sector;
        }).eq(0);
        sectorElem.find('.subgroup-'+subsector).show();
    }
    function createForSector(s) {
        var tbody = $('<tbody />');
        var sector = Sectors.pluck(s);
        var div = $('<div />')
                        .addClass('facility-display')
                        .data('sector', sector.slug);
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
            $('<td />', {'class': classesStr(col)})
                .text(i)
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
                .data('subsector', sg.slug)
                .addClass('sub-sector-link-'+sg.slug)
                .click(function(){
                    select(sector.slug, $(this).data('subsector'));
                })
                .appendTo(p);
            if(i < sgl - 1)
                $('<span />').text(' | ').appendTo(p);
        });
        return p;
    }
    function classesStr(col) {
        return _.map(col.subgroups, function(sg){
            return 'subgroup-'+sg
        }).join(' ');
    }
    function _createHeadRow(sector, cols) {
        var tr = $('<tr />');
        _.each(cols, function(col, i){
            $('<th />', {'class': classesStr(col)})
                .text(col.name)
                .appendTo(tr);
        });
        return tr;
    }
    return {
        createForSectors: createForSectors,
        select: select
    };
})();
