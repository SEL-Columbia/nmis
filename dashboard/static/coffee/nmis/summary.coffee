do ->
  ###
  When "summary" is activated/deactivated, the open/close callbacks are called
  ###
  panelOpen = ->
    NMIS.LocalNav.show()
    $("#conditional-content").show()

  panelClose = ->
    NMIS.LocalNav.hide()
    $("#conditional-content").hide()

  NMIS.panels.getPanel("summary").addCallbacks open: panelOpen, close: panelClose

_bcKeys = "state lga mode sector subsector indicator".split(" ")

NMIS.Env.onChange (next, prev)->
  # log "Changing mode"  if @changing "mode"
  # log "Changing LGA"  if @changing "lga"

  if @changing "lga"
    $("#conditional-content").remove()

  if @changingToSlug "mode", "summary"
    # This runs only when the environment is *changing to* the "mode" of "summary"
    NMIS.panels.changePanel "summary"

  if @usingSlug "mode", "summary"
    # This runs when the upcoming environment matches "mode" of "facilities"
    NMIS.Breadcrumb.clear()

    NMIS.Breadcrumb.setLevels NMIS._prepBreadcrumbValues next, _bcKeys, state: next.state, lga: next.lga
    NMIS.LocalNav.markActive ["mode:summary", "sector:#{next.sector.slug}"]
    NMIS.LocalNav.iterate (sectionType, buttonName, a) ->
      o = {}
      o[sectionType] = buttonName
      a.attr "href", NMIS.urlFor.extendEnv o
    if @usingSlug("sector", "overview") or @changing "lga"
      @change.done (env)->
        # This callback is triggered when NMIS.Env.changeDone()
        # is called (in this case, after google maps script has loaded)
        launchGoogleMapSummaryView env.lga


NMIS.loadSummary = (s) ->
  # called before the data is loaded into the page.
  # this prepares the dom and launches the AJAX requests.
  lga_code = "#{s.params.state}/#{s.params.lga}"
  lga = NMIS.getDistrictByUrlCode(lga_code)
  NMIS.districtDropdownSelect lga

  state = lga.group

  fetchers = {}

  googleMapsLoad = NMIS.loadGoogleMaps()

  if lga.has_data_module("presentation/summary_sectors")
    fetchers.summary_sectors = lga.loadSummarySectors()
    fetchers.summary_sectors.done ->
      current_sector = do (vd=lga.ssData.view_details)->
        for sector in vd when sector.id is s.params.sector
          return {
            slug: sector.id
            name: sector.name
          }
        # if no sector matches,
        # then set current_sector to "overview"
        name: "Overview"
        slug: "overview"

      NMIS.Env
        mode:
          name: "Summary"
          slug: "summary"
        state: state
        lga: lga
        sector: current_sector

  fetchers.lga_data = lga.loadData()  if lga.has_data_module("data/lga_data")
  fetchers.variables = lga.loadVariables()

  $.when_O(fetchers).done (results)->
    launch_summary s.params, state, lga, results
    googleMapsLoad.done ->
      NMIS.Env.changeDone()

launchGoogleMapSummaryView = (lga)->
  $mapDiv = $(".profile-box .map").eq(0)
  mapDiv = $mapDiv.get(0)
  ll = (+x for x in lga.latLng.split(","))
  mapZoom = lga.zoomLevel || 9
  if mapDiv
    summaryMap = new google.maps.Map(mapDiv,
      zoom: mapZoom
      center: new google.maps.LatLng(ll[1], ll[0])
      streetViewControl: false
      panControl: false
      mapTypeControl: false
      mapTypeId: google.maps.MapTypeId.HYBRID
    )
    summaryMap.mapTypes.set "ng_base_map", do ->
      tileset = "nigeria_base"
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

    summaryMap.setMapTypeId "ng_base_map"
    _rDelay 1, ->
      google.maps.event.trigger summaryMap, "resize"
      summaryMap.setCenter new google.maps.LatLng(ll[1], ll[0]), mapZoom

launch_summary = (params, state, lga, query_results={})->
  relevant_data = lga.ssData.relevant_data
  NMIS.DisplayWindow.setDWHeight()

  view_details = lga.ssData.view_details

  content_div = $('.content')
  if content_div.find('#conditional-content').length == 0
    cc_div = build_all_sector_summary_modules(lga)
    cc_div.appendTo content_div

  sector = NMIS.Env().sector
  cc = $("#conditional-content").hide()
  cc.find(">div").hide()
  cc.find(">div.lga." + sector.slug).show()
  cc.show()

build_all_sector_summary_modules = (lga)->
  cc_div = $ '<div>', id: 'conditional-content'

  context =
    lga: lga
    summary_sectors: lga.ssData.sectors

  for sector_view_panel in lga.ssData.view_details
    sector_window = $("<div>", class: "lga")
    sector_window.html("<div class='display-window-bar breadcrumb'></div>")
    sector_window_inner_wrap = $("<div>", class:'cwrap').appendTo(sector_window)
    sector_id = sector_view_panel.id
    sector_window.addClass sector_id
    context.summary_sector = context.summary_sectors[sector_id]
    context.view_panel = sector_view_panel
    for module in sector_view_panel.modules
      sectorPanel = do ->
        spanStr = (content="&mdash;", cls="")-> "<span class='#{cls}' style='text-transform:none'>#{content}</span>"
        establish_template_display_panels()
        context.relevant_data = lga.ssData.relevant_data[sector_id]?[module]
        div = $('<div>')
        context.lookupName = (id, context)->
          if id
            vrb = lga.variableSet.find id
            if vrb
              spanStr vrb.lookup("name", context), "variable-name"
            else
              spanStr id, "warn-missing"
          else
            spanStr "No variable id", "warn-missing"
        context.lookupValue = (id, defaultValue=null)->
          record = lga.lookupRecord(id)
          if record
            spanStr record.displayValue(), "found"
          else if id
            spanStr "&ndash;", "warn-missing", "Missing value for id: #{id}"
          else
            spanStr "&cross;", "warn-missing", "Missing ID"
        if __display_panels[module]?
          panel = __display_panels[module]
          panel.build div, context
        else
          div.html template_not_found(module)
        div
      sector_window_inner_wrap.append sectorPanel
    sector_window.appendTo cc_div
  cc_div

__display_panels = {}
class DisplayPanel
  constructor: ()->
  build: ()->

class UnderscoreTemplateDisplayPanel extends DisplayPanel
  constructor: (module, elem)->
    @template_html = elem.html()
  build: (elem, context={})->
    elem.append _.template(@template_html, context)

template_not_found = (name)-> "<h2>Template '#{name}' not found</h2>"

_tdps = false
establish_template_display_panels = ()->
  unless _tdps
    $('script.display-panel').each ()->
      $this = $(this)
      module = $this.data('module')
      __display_panels[module] = new UnderscoreTemplateDisplayPanel(module, $this)
    _tdps = true

# identical to _.delay except switches the order of the parameters
_rDelay = (i, fn)-> _.delay fn, i