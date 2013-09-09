###
Facilities:
###

do ->
  panelOpen = ()->
    NMIS.DisplayWindow.show()
    NMIS.LocalNav.show()

  panelClose = ()->
    NMIS.DisplayWindow.hide()
    NMIS.LocalNav.hide()

  NMIS.panels.getPanel("facilities").addCallbacks open: panelOpen, close: panelClose

facilitiesMode =
  name: "Facility Detail"
  slug: "facilities"

# used in the breadcrumb
_standardBcSlugs = "state lga mode sector subsector indicator".split(" ")

NMIS.Env.onChange (next, prev)->
  # log "Changing mode"  if @changing "mode"
  # log "Changing LGA"  if @changing "lga"

  if @changingToSlug "mode", "facilities"
    # This runs only when the environment is *changing to* the "mode" of "facilities"
    NMIS.panels.changePanel "facilities"

  if @usingSlug "mode", "facilities"
    # This runs when the upcoming environment matches "mode" of "facilities"
    NMIS.LocalNav.markActive ["mode:facilities", "sector:#{next.sector.slug}"]

    NMIS.Breadcrumb.clear()
    NMIS.Breadcrumb.setLevels NMIS._prepBreadcrumbValues next, _standardBcSlugs, state: next.state, lga: next.lga

    # Not sure how NMIS.activeSector is used.
    # Potentially could be removed in favor of NMIS.Env().sector
    NMIS.activeSector next.sector
    # setting datawindow height to "calculate" means that the datawindow's
    # height will be calculated from the total available height minus padding
    NMIS.DisplayWindow.setDWHeight "calculate"

    NMIS.LocalNav.iterate (sectionType, buttonName, a) ->
      env = _.extend {}, next, subsector: false
      env[sectionType] = buttonName
      a.attr "href", NMIS.urlFor env


    ###
    determine which map changes should be made
    ###
    if @changing("lga") or @changingToSlug("mode", "facilities")
      repositionMapToDistrictBounds = true
      addIcons = true
    if @changing("sector")
      if next.sector.slug is "overview"
        featureAllIcons = true
      else
        featureIconsOfSector = next.sector
    if @changing("facility")
      if next.facility
        highlightFacility = next.facility
      else
        hideFacility = true
    if @usingSlug "sector", "overview"
      loadLgaData = true

    resizeDisplayWindowAndFacilityTable()

    @change.done ()->
      if next.sector.slug is "overview"
        displayOverview(next.lga)
      else
        displayFacilitySector(next.lga, NMIS.Env())

      withFacilityMapDrawnForDistrict(next.lga).done (nmisMapContext)->
        nmisMapContext.fitDistrictBounds(next.lga)  if repositionMapToDistrictBounds
        nmisMapContext.addIcons()  if addIcons
        nmisMapContext.featureAllIcons()  if featureAllIcons
        nmisMapContext.featureIconsOfSector(featureIconsOfSector)  if featureIconsOfSector
        NMIS.FacilitySelector.activate id: highlightFacility  if highlightFacility
        NMIS.FacilityPopup.hide()  if hideFacility

    do =>
      # Fetch all data
      district = next.lga
      fetchers =
        presentation_facilities: district.loadFacilitiesPresentation()
        data_facilities: district.loadFacilitiesData()
        variableList: district.loadVariables()

      fetchers.lga_data = district.loadData()  if loadLgaData and district.has_data_module("data/lga_data")

      # when data is fetched, trigger the "changeDone" callback
      $.when_O(fetchers).done ()=> @changeDone()

ensure_dw_resize_set = _.once ->
  NMIS.DisplayWindow.addCallback "resize", (tf, size) ->
    resizeDisplayWindowAndFacilityTable()  if size is "middle" or size is "full"

NMIS.launch_facilities = ->
  params = {}

  params.facility = do ->
    urlEnd = "#{window.location}".split("?")[1]
    urlEnd.match /facility=([0-9a-f-]+)$/  if urlEnd

  for own paramName, val of @params when $.type(val) is "string" and val isnt ""
    params[paramName] = val.replace "/", ""

  district = NMIS.getDistrictByUrlCode "#{params.state}/#{params.lga}"
  NMIS.districtDropdownSelect district

  params.sector = `undefined`  if params.sector is "overview"

  ###
  We ALWAYS need to load the sectors first (either cached or not) in order
  to determine if the sector is valid.
  ###
  district.sectors_data_loader().done ->
    # once the sectors are downloaded, we can set the environment
    # variables.

    NMIS.Env do ->
      ###
      This self-invoking function returns and sets the environment
      object which we will be using for the page view.
      ###
      e =
        lga: district
        state: district.group
        mode: facilitiesMode
        sector: NMIS.Sectors.pluck params.sector

      e.subsector = e.sector.getSubsector params.subsector  if params.subsector
      e.indicator = e.sector.getIndicator params.indicator  if params.indicator
      e.facility = params.facility  if params.facility
      e

NMIS.mapClick = ()->
  if NMIS.FacilitySelector.isActive()
    NMIS.FacilitySelector.deselect()
    dashboard.setLocation NMIS.urlFor.extendEnv facility: false

withFacilityMapDrawnForDistrict = do ->
  # gmap is the persisent link to the google.maps.Map object
  gmap = false
  $elem = elem = false

  # in this context, district points to the most recently
  # drawn district.
  district = false

  _createMap = ()->
    gmap = new google.maps.Map elem,
      streetViewControl: false
      panControl: false
      mapTypeControlOptions:
        mapTypeIds: ["roadmap", "satellite", "terrain", "OSM"]
      mapTypeId: google.maps.MapTypeId["SATELLITE"]

    google.maps.event.addListener gmap, "click", NMIS.mapClick

    gmap.overlayMapTypes.insertAt 0, do ->
      tileset = "nigeria_overlays_white"
      name = "Nigeria"
      maxZoom = 17
      new google.maps.ImageMapType
        getTileUrl: (coord, z) -> "http://b.tiles.mapbox.com/v3/modilabs.#{tileset}/#{z}/#{coord.x}/#{coord.y}.png"
        name: name
        alt: name
        tileSize: new google.maps.Size(256, 256)
        isPng: true
        minZoom: 0
        maxZoom: maxZoom

    gmap.mapTypes.set "OSM", new google.maps.ImageMapType
      getTileUrl: (c, z) -> "http://tile.openstreetmap.org/#{z}/#{c.x}/#{c.y}.png"
      tileSize: new google.maps.Size(256, 256)
      name: "OSM"
      maxZoom: 18

  _addIconsAndListeners = ()->
    iconURLData = (item) ->
      status = item.status
      return item._custom_png_data  if status is "custom"
      slug = item.iconSlug or item.sector?.slug or 'default'
      iconFiles =
        education: "education.png"
        health: "health.png"
        water: "water.png"
        default: "default.png"
      filenm = iconFiles[slug] or iconFiles.default
      # throw new Error("Status is undefined")  unless status?
      ["#{NMIS.settings.pathToMapIcons}/icons_f/#{status}_#{filenm}", 32, 24]
    markerClick = ->
      sslug = NMIS.activeSector().slug
      if sslug is @nmis.item.sector.slug or sslug is "overview"
        dashboard.setLocation NMIS.urlFor.extendEnv facility: @nmis.id
    markerMouseover = ->
      sslug = NMIS.activeSector().slug
      NMIS.FacilityHover.show this  if @nmis.item.sector.slug is sslug or sslug is "overview"
    markerMouseout = ->
      NMIS.FacilityHover.hide()

    NMIS.IconSwitcher.setCallback "createMapItem", (item, id, itemList) ->
      if !!item._ll and not @mapItem(id)
        $gm = google.maps
        item.iconSlug = item.iconType or item.sector?.slug
        item.status = "normal"  unless item.status
        [iurl, iw, ih] = iconURLData(item)

        iconData = url: iurl, size: new $gm.Size(iw, ih)

        mI =
          latlng: new $gm.LatLng(item._ll[0], item._ll[1])
          icon: new $gm.MarkerImage(iconData.url, iconData.size)

        mI.marker = new $gm.Marker
          position: mI.latlng
          map: gmap
          icon: mI.icon

        mI.marker.setZIndex (if item.status is "normal" then 99 else 11)
        mI.marker.nmis = item: item, id: id

        $gm.event.addListener mI.marker, "click", markerClick
        $gm.event.addListener mI.marker, "mouseover", markerMouseover
        $gm.event.addListener mI.marker, "mouseout", markerMouseout
        @mapItem id, mI

    NMIS.IconSwitcher.createAll()

    NMIS.IconSwitcher.setCallback "shiftMapItemStatus", (item, id) ->
      mapItem = @mapItem(id)
      unless not mapItem
        icon = mapItem.marker.getIcon()
        icon.url = iconURLData(item)[0]
        mapItem.marker.setIcon icon

  nmisMapContext = do ->
    createMap = ()-> _createMap()

    addIcons = ()-> _addIconsAndListeners()

    fitDistrictBounds = (_district=false)->
      district = _district  if _district
      createMap()  unless gmap
      throw new Error("Google map [gmap] is not initialized.")  unless gmap
      [swLat, swLng, neLat, neLng] = district.latLngBounds()
      bounds = new google.maps.LatLngBounds new google.maps.LatLng(swLat, swLng), new google.maps.LatLng(neLat, neLng)
      gmap.fitBounds bounds

    featureAllIcons = ()->
      NMIS.IconSwitcher.shiftStatus () -> "normal"

    featureIconsOfSector = (sector)->
      NMIS.IconSwitcher.shiftStatus (id, item) ->
        (if item.sector.slug is sector.slug then "normal" else "background")

    selectFacility = (fac)->
      NMIS.IconSwitcher.shiftStatus (id, item) ->
        (if item.id is id then "normal" else "background")

    createMap: createMap
    addIcons: addIcons
    fitDistrictBounds: fitDistrictBounds
    featureAllIcons: featureAllIcons
    featureIconsOfSector: featureIconsOfSector
    selectFacility: selectFacility
    

  (_district)->
    ###
    This function is set to "withFacilityMapDrawnForDistrict" but always executed in this scope.
    ###
    dfd = $.Deferred()

    $elem = $(NMIS._wElems.elem0)
    district = _district
    elem = $elem.get(0)
    existingMapDistrictId = $elem.data("districtId")

    NMIS.loadGoogleMaps().done ()-> dfd.resolve nmisMapContext

    dfd.promise()

resizeDisplayWindowAndFacilityTable = ->
  ah = NMIS._wElems.elem1.height()
  bar = $(".display-window-bar", NMIS._wElems.elem1).outerHeight()
  cf = $(".clearfix", NMIS._wElems.elem1).eq(0).height()
  NMIS.SectorDataTable.setDtMaxHeight ah - bar - cf - 18


displayOverview = (district)->
  profileVariables = district.facilitiesPresentation.profile_indicator_ids
  NMIS._wElems.elem1content.empty()
  displayTitle = "Facility Detail: #{district.label} » Overview"
  NMIS.DisplayWindow.setTitle displayTitle
  NMIS.IconSwitcher.shiftStatus (id, item) ->
    "normal"

  obj =
    lgaName: "#{district.name}, #{district.group.name}"

  obj.profileData = do ->
    outp = for vv in profileVariables
      variable = district.variableSet.find(vv)
      value = district.lookupRecord vv

      name: variable?.name
      value: value?.value
    outp

  facCount = 0
  obj.overviewSectors = for s in NMIS.Sectors.all()
    c = 0
    c++ for own d, item of NMIS.data() when item.sector is s
    facCount += c

    name: s.name
    slug: s.slug
    url: NMIS.urlFor(_.extend(NMIS.Env(), sector: s, subsector: false))
    counts: c

  obj.facCount = facCount

  NMIS._wElems.elem1content.html _.template($("#facilities-overview").html(), obj)

displayFacilitySector = (lga, e)->
  if 'subsector' not in e or not NMIS.FacilitySelector.isActive()
    NMIS.IconSwitcher.shiftStatus (id, item) ->
      (if item.sector is e.sector then "normal" else "background")

  displayTitle = "Facility Detail: #{lga.label} » #{e.sector.name}"
  NMIS.DisplayWindow.setTitle displayTitle, displayTitle + " - " + e.subsector.name  unless not e.subsector

  NMIS._wElems.elem1content.empty()
  twrap = $("<div />",
    class: "facility-table-wrap"
  ).append($("<div />").attr("class", "clearfix").html("&nbsp;")).appendTo(NMIS._wElems.elem1content)

  defaultSubsector = e.sector.subGroups()[0]
  eModded = if 'subsector' not in e then _.extend({}, e, subsector: defaultSubsector) else e
  tableElem = NMIS.SectorDataTable.createIn(lga, twrap, eModded, sScrollY: 1000).addClass("bs")
  unless not e.indicator
    do ->
      if e.indicator.iconify_png_url
        NMIS.IconSwitcher.shiftStatus (id, item) ->
          if item.sector is e.sector
            item._custom_png_data = e.indicator.customIconForItem(item)
            "custom"
          else
            "background"

      return  if e.indicator.click_actions.length is 0
      $(".indicator-feature").remove()
      obj = _.extend({}, e.indicator)
      mm = $ _.template($("#indicator-feature").html(), obj)
      mm.find("a.close").click ->
        dashboard.setLocation NMIS.urlFor _.extend({}, e, indicator: false)
        false

      mm.prependTo NMIS._wElems.elem1content

      pcWrap = mm.find(".raph-circle").get(0)
      do ->
        sector = e.sector
        column = e.indicator
        piechartTrue = _.include(column.click_actions, "piechart_true")
        piechartFalse = _.include(column.click_actions, "piechart_false")
        pieChartDisplayDefinitions = undefined
        if piechartTrue
          # """
          # legend,color,key
          # No,#f55,false
          # Yes,#21c406,true
          # Undefined,#999,undefined
          # """
          pieChartDisplayDefinitions = [
            legend: "No"
            color: "#ff5555"
            key: "false"
          ,
            legend: "Yes"
            color: "#21c406"
            key: "true"
          ,
            legend: "Undefined"
            color: "#999"
            key: "undefined"
          ]
        else if piechartFalse
          pieChartDisplayDefinitions = [
            legend: "Yes"
            color: "#ff5555"
            key: "true"
          ,
            legend: "No"
            color: "#21c406"
            key: "false"
          ,
            legend: "Undefined"
            color: "#999"
            key: "undefined"
          ]
        unless not pieChartDisplayDefinitions
          tabulations = NMIS.Tabulation.sectorSlug(sector.slug, column.slug, "true false undefined".split(" "))
          prepare_data_for_pie_graph pcWrap, pieChartDisplayDefinitions, tabulations, {}


prepare_data_for_pie_graph = (pieWrap, legend, data, _opts) ->
  ###
  creates a graph with some default options.
  if we want to customize stuff (ie. have behavior that changes based on
  different input) then we should work it into the "_opts" parameter.
  ###
  unless gid = $(pieWrap).eq(0).prop "id"
    $(pieWrap).prop "id", "pie-wrap"
    gid = "pie-wrap"

  defaultOpts =
    x: 50
    y: 40
    r: 35
    font: "12px 'Fontin Sans', Fontin-Sans, sans-serif"

  opts = $.extend({}, defaultOpts, _opts)

  rearranged_vals = $.map legend, (val) -> $.extend val, value: data[val.key]
  rearranged_vals2 = (val.value = data[val.key]  for val in legend)

  pvals =
    values: []
    colors: []
    legend: []

  rearranged_vals.sort (a, b) -> b.value - a.value

  for item in rearranged_vals
    if item.value > 0
      pvals.values.push item.value
      pvals.colors.push item.color
      pvals.legend.push "%% - #{item.legend} (##)"

  ###
  NOTE: hack to get around a graphael bug!
  if there is only one color the chart will
  use the default value (Raphael.fn.g.colors[0])
  here, we will set it to whatever the highest
  value that we have is
  ###
  Raphael.fn.g.colors[0] = pvals.colors[0]
  #

  r = Raphael(gid)
  r.g.txtattr.font = opts.font
  pie = r.g.piechart(opts.x, opts.y, opts.r, pvals.values,
    colors: pvals.colors
    legend: pvals.legend
    legendpos: "east"
  )
  hover_on = ->
    @sector.stop()
    @sector.scale 1.1, 1.1, @cx, @cy
    if @label
      @label[0].stop()
      @label[0].scale 1.4
      @label[1].attr "font-weight": 800
  hover_off = ->
    @sector.animate
      scale: [1, 1, @cx, @cy]
    , 500, "bounce"
    if @label
      @label[0].animate
        scale: 1
      , 500, "bounce"
      @label[1].attr "font-weight": 400
  pie.hover hover_on, hover_off
  r


# identical to _.delay except switches the order of the parameters
_rDelay = (i, fn)-> _.delay fn, i
