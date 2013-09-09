do ->
  NMIS.SectorDataTable = do ->
    ###
    This creates the facilities data table.

    (seen at #/state/district/facilites/health)
    [wrapper element className: ".facility-table-wrap"]
    ###
    dt = undefined
    table = undefined
    tableSwitcher = undefined

    createIn = (district, tableWrap, env, _opts) ->
      opts = _.extend(
        sScrollY: 120
      , _opts)
      data = district.facilityDataForSector env.sector.slug
      throw (new Error("Subsector is undefined"))  if env.subsector is `undefined`
      env.subsector = env.sector.getSubsector(env.subsector.slug)
      columns = env.subsector.columns()
      tableSwitcher.remove()  if tableSwitcher
      tableSwitcher = $("<select />")
      _.each env.sector.subGroups(), (sg) ->
        $("<option />").val(sg.slug).text(sg.name).appendTo tableSwitcher

      table = $("<table />").addClass("facility-dt").append(_createThead(columns)).append(_createTbody(columns, data))
      tableWrap.append table
      dataTableDraw = (s) ->
        dt = table.dataTable(
          sScrollY: s
          bDestroy: true
          bScrollCollapse: false
          bPaginate: false
          fnDrawCallback: ->
            newSelectDiv = undefined
            ts = undefined
            $(".dataTables_info", tableWrap).remove()
            if $(".dtSelect", tableWrap).get(0) is `undefined`
              ts = getSelect()
              newSelectDiv = $("<div />",
                class: "dataTables_filter dtSelect left"
              ).html($("<p />").text("Grouping:").append(ts))
              $(".dataTables_filter", tableWrap).parents().eq(0).prepend newSelectDiv
              ts.val env.subsector.slug
              ts.change ->
                ssSlug = $(this).val()
                nextUrl = NMIS.urlFor(_.extend({}, env,
                  subsector: env.sector.getSubsector(ssSlug)
                ))
                dashboard.setLocation nextUrl

        )
        tableWrap

      dataTableDraw opts.sScrollY
      table.delegate "tr", "click", ->
        dashboard.setLocation NMIS.urlFor.extendEnv(facility: $(this).data("rowData"))

      table

    getSelect = -> tableSwitcher.clone()

    setDtMaxHeight = (ss) ->
      tw = undefined
      h1 = undefined
      h2 = undefined
      tw = dataTableDraw(ss)
    
      # console.group("heights");
      # log("DEST: ", ss);
      h1 = $(".dataTables_scrollHead", tw).height()
    
      # log(".dataTables_scrollHead: ", h);
      h2 = $(".dataTables_filter", tw).height()
    
      # log(".dataTables_filter: ", h2);
      ss = ss - (h1 + h2)
    
      # log("sScrollY: ", ss);
      dataTableDraw ss
  
    # log(".dataTables_wrapper: ", $('.dataTables_wrapper').height());
    # console.groupEnd();
    handleHeadRowClick = ->
      column = $(this).data("column")
      ind = NMIS.Env().sector.getIndicator(column.slug)

      if ind and ind.clickable
        env = NMIS.Env.extend(indicator: ind.slug)
        unless env.subsector
          env.subsector = env.sector.subGroups()[0]
        newUrl = NMIS.urlFor(env)
        dashboard.setLocation newUrl

    _createThead = (cols) ->
      row = $("<tr />")
      startsWithType = cols[0].name is "Type"
      _.each cols, (col, ii) ->
        $("<th />").text("Type").appendTo row  if ii is 1 and not startsWithType
        row.append $("<th />").text(col.name).data("column", col)

      row.delegate "th", "click", handleHeadRowClick
      $("<thead />").html row

    nullMarker = ->
      $("<span />").html("&mdash;").addClass "null-marker"

    resizeColumns = ->
      dt.fnAdjustColumnSizing()  unless not dt

    _createTbody = (cols, rows) ->
      tbody = $("<tbody />")
      _.each rows, (r) ->
        row = $("<tr />")
        if r.id is `undefined`
          console.error "Facility does not have an ID defined:", r
        else
          row.data "row-data", r.id
        startsWithType = cols[0].name is "Type"
        _.each cols, (c, ii) ->
        
          # quick fixes in this function scope will need to be redone.
          if ii is 1 and not startsWithType
            ftype = r.facility_type or r.education_type or r.water_source_type or "unk"
            $("<td />").attr("title", ftype).addClass("type-icon").html($("<span />").addClass("icon").addClass(ftype).html($("<span />").text(ftype))).appendTo row
          z = r[c.slug] or nullMarker()
        
          # if(!NMIS.DisplayValue) throw new Error("No DisplayValue")
          td = NMIS.DisplayValue.inTdElem(r, c, $("<td />"))
          row.append td

        tbody.append row

      tbody

    dataTableDraw = ->

    createIn: createIn
    setDtMaxHeight: setDtMaxHeight
    getSelect: getSelect
    resizeColumns: resizeColumns
