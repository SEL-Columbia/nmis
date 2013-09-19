#begin a_init_nmis.coffee

# All the NMIS Modules interact with each other via the globally
# accessible NMIS object. This is why the modules are wrapped in
# a "do->" closure scope-- to ensure that there are no hidden
# references to distant parts of the NMIS codebase.
@NMIS = NMIS = {}

# There are a handful of NMIS.settings values which can be set
# to influence which URLs the application uses to look for things.
unless NMIS.settings
  NMIS.settings =
    openLayersRoot: "./openlayers/"
    leafletRoot: "./leaflet/"
    pathToMapIcons: "./images"

  # in this app, underscore templates use a different syntax to avoid
  # conflicts with django and erb
  _.templateSettings =
    escape: /<{-([\s\S]+?)}>/g
    evaluate: /<{([\s\S]+?)}>/g
    interpolate: /<{=([\s\S]+?)}>/g

do ->
  # NMIS.expected_modules was used in nmis_ui tests to ensure that
  # all of the necessary modules (and files) had been loaded in.
  # This is less important if everything is in one file.
  NMIS.expected_modules = ["Tabulation","clear","Sectors","validateData","data","FacilityPopup","Breadcrumb","IconSwitcher","MapMgr","FacilityHover"]

do ->

  # This is the abdomen of the NMIS code. NMIS.init() initializes "data" and "opts"
  # which were used a lot in the early versions.

  # Many modules still access [facility-]data through NMIS.data()

  # opts has more-or-less been replaced by NMIS.Env()

  data = false
  opts = false

  NMIS.init = (_data, _opts) ->
    opts = _.extend(
      iconSwitcher: true
      sectors: false
    , _opts)
    data = {}
    NMIS.loadSectors opts.sectors  unless not opts.sectors
    NMIS.loadFacilities _data
    if opts.iconSwitcher
      NMIS.IconSwitcher.init
        items: data
        statusShiftDone: ->
          tally = {}
          for item in @items
            tally[item.status] = 0  unless tally[item.status]
            tally[item.status]++
    true

  NMIS.loadSectors = (_sectors, opts) ->
    NMIS.Sectors.init _sectors, opts

  cloneParse = (d) ->
    datum = _.clone(d)
    if datum.gps is `undefined`
      datum._ll = false
    else if _.isString datum.gps
      ll = datum.gps.split(" ")
      datum._ll = [ll[0], ll[1]]
    else
      datum._ll = false
    if datum.sector
        sslug = datum.sector.toLowerCase()
        datum.sector = NMIS.Sectors.pluck(sslug)
    datum

  NMIS.loadFacilities = (_data, opts) ->
    _.each _data, (val, key) ->
      val.id = val.uuid
      throw new Error("UUID Missing for facility") unless val.id
      data[val.id] = cloneParse(val)

  NMIS.clear = ->
    data = []
    NMIS.Sectors.clear()

  NMIS.validateData = ->
    NMIS.Sectors.validate()
    _(data).each (datum) ->
      datum._uid = _.uniqueId("fp")  if datum._uid is `undefined`

    _(data).each (datum) ->
      if datum._latlng is `undefined` and datum.gps isnt `undefined`
        llArr = datum.gps.split(" ")
        datum._latlng = [llArr[0], llArr[1]]
    true

  NMIS.activeSector = do ->
    currentSector = false
    (sector) ->
      if sector is `undefined`
        currentSector
      else
        currentSector = sector


  #uses: NMIS.Sectors, data
  # NMIS.dataObjForSector = (sectorSlug) ->
  #   sector = NMIS.Sectors.pluck(sectorSlug)
  #   o = {}
  #   _(data).each (datum, id) ->
  #     o[id] = datum  if datum.sector.slug is sector.slug
  #   o

  # This is how other modules access the data that has been loaded into NMIS.
  NMIS.data = -> data

do ->
  # the internal "value" function takes a value and returns a 1-2 item list:
  # The second returned item (when present) is a class name that should be added
  # to the display element.

  #   examples:
  
  #   value(null)
  #   //  ["--", "val-null"]
  
  #   value(0)
  #   //  ["0"]
  
  #   value(true)
  #   //  ["Yes"]

  value = (v, variable={}) ->
    r = [v]
    if v is `undefined`
      r = ["&mdash;", "val-undefined"]
    else if v is null
      r = ["null", "val-null"]
    else if v is true
      r = ["Yes"]
    else if v is false
      r = ["No"]
    else unless isNaN(+v)
      r = [round_down(v, variable.precision)]
    else if $.type(v) is "string"
      r = [NMIS.HackCaps(v)]
    r

  # The main function, "NMIS.DisplayValue" receives an element
  # and displays the appropriate value.
  DisplayValue = (d, element) ->
    res = value(d)
    element.addClass res[1]  if res[1]?
    element.html res[0]
    element

  DisplayValue.raw = value

  # Sometimes, indicators require special classes
  DisplayValue.special = (v, indicator) ->
    r = value(v)
    o =
      name: indicator.name
      classes: ""
      value: r[0]

    classes = ""
    if indicator.display_style is "checkmark_true"
      classes = "label "
      if v is true
        classes += "chk-yes"
      else if v is false
        classes += "chk-no"
      else
        classes += "chk-null"
    else if indicator.display_style is "checkmark_false"
      classes = "label "
      if v is true
        classes += "chk-no"
      else if v is false
        classes += "chk-yes"
      else
        classes += "chk-null"
    o.classes = classes
    o

  # displaying values directly in a TD element (with a wrapping span)
  DisplayValue.inTdElem = (facility, indicator, elem) ->
    vv = facility[indicator.slug]
    c = value(vv)
    chkY = indicator.display_style is "checkmark_true"
    chkN = indicator.display_style is "checkmark_false"
    if chkY or chkN
      oclasses = "label "
      if $.type(vv) is "boolean"
        if vv
          oclasses += (if chkY then "chk-yes" else "chk-no")
        else
          oclasses += (if chkY then "chk-no" else "chk-yes")
      else
        oclasses += "chk-null"
      c[0] = $("<span />").addClass(oclasses).html(c[0])
    elem.html c[0]

  round_down = (v, decimals=2) ->
    d = Math.pow(10, decimals)
    Math.floor(v * d) / d

  NMIS.DisplayValue = DisplayValue

error = (message, opts={})-> log.error message
NMIS.error = error

# begin a_nmis.coffee

# NMIS.Breadcrumb--
#   init # set the elem that the breadcrumb will build into
NMIS.Breadcrumb = do ->
  levels = []
  elem = false
  context = {}

  init = (_elem, opts={}) ->
    # NMIS.Breadcrumb.init
    # set the elem that the breadcrumb will build into
    elem = $(_elem).eq(0)

    opts.draw = true  unless opts.draw?
    setLevels opts.levels, false  if opts.levels?
    draw()  unless not opts.draw
  clear = ->
    # NMIS.Breadcrumb.clear
    # Empty the existing breadcrumb elem and clear out set values.
    elem.empty()  if elem
    levels = []
  setLevels = (new_levels=[], needs_draw=true) ->
    # NMIS.Breadcrumb.setLevels
    # Pass an array of levels of objects which will be built into
    # the breadcrumb elem.
    levels[i] = level for level, i in new_levels when level?
    draw()  if needs_draw
    context
  setLevel = (ln, d) ->
    # pass 2 arguments: an index number and a value.
    levels[ln] = d
    context
  draw = ->
    # Draws the breadcrumb with the most recently assigned values.
    throw new Error "Breadcrumb: elem is undefined" unless elem?
    elem.empty()
    splitter = $("<span>").text("/")
    for [txt, href, fn], i in levels
      splitter.clone().appendTo elem  if i isnt 0
      a = $("<a>").text(txt).attr("href", href)
      a.click fn if fn?
      a.appendTo elem
    elem

  init: init
  setLevels: setLevels
  setLevel: setLevel
  draw: draw
  _levels: -> levels
  clear: clear


do ->
  # A consistent way to handle the URL naming of photos which are
  # stored in the items and in different places (of Amazon S3 accounts)
  # depending on the item.
  NMIS.S3Photos = do ->
    s3Root = "http://nmisstatic.s3.amazonaws.com/facimg"
    url: (s3id, size=0)->
      [code, id] = s3id.split ":"
      "#{s3Root}/#{code}/#{size}/#{id}.jpg"

  NMIS.S3orFormhubPhotoUrl = (item, size_code)->
    sizes =
      "90": "-small"
      "200": "-medium"
    if item.formhub_photo_id
      fh_pid = "#{item.formhub_photo_id}".replace ".jpg", ""
      if size_code in sizes
        fh_pid = "#{fh_pid}#{sizes[size_code]}"
      "https://formhub.s3.amazonaws.com/ossap/attachments/#{fh_pid}.jpg"
    else if item.s3_photo_id
      NMIS.S3Photos.url item.s3_photo_id, size_code

# Sometimes, when we want to turn a_slug_with_underscores into a
# pretty name, we can use this function to turn it in to
# "A Slug With Underscores". However this is not recommended because
# it restricts what we use as slugs and forces us away from using
# a proper name attribute with proper capitalization and punctuation.

NMIS.HackCaps = do ->

  capitalize = (str) ->
    if str then (str[0].toUpperCase() + str.slice(1)) else ""

  (str)->
    if $.type(str) is "string"
      output = []
      for section in str.split "_"
        output.push capitalize section
      output.join ' '
    else
      str

# NMIS.IconSwitcher provides a way to iterate over a set of icons from
# different parts of the application (and before the icons have been created)
# and define callbacks which will do things like change the icons as the
# state of the map changes.
NMIS.IconSwitcher = do ->
  context = {}
  callbacks = ["createMapItem", "shiftMapItemStatus", "statusShiftDone", "hideMapItem", "showMapItem", "setMapItemVisibility"]
  mapItems = {}

  init = (_opts) ->
    noop = ->
    items = {}
    context = _.extend(items: {}, mapItem: mapItem, _opts)
    for cbname in callbacks
      context[cbname] = noop  if context[cbname] is `undefined`
    true

  mapItem = (id, value) ->
    if !value?
      mapItems[id]
    else
      mapItems[id] = value

  # these aren't used, but they give an idea of how the hidden attribute changes the visibility.
  hideItem = (item) -> item.hidden = true
  showItem = (item) -> item.hidden = false

  # set an items visibility to true or false
  # returns true if visibility has changed
  setVisibility = (item, tf) ->
    unless not tf
      unless item.hidden
        item.hidden = true
        context.setMapItemVisibility.call item, false, item, context.items
        return true
    else
      unless not item.hidden
        item.hidden = false
        context.setMapItemVisibility.call item, true, item, context.items
        return true
    false

  # run a callback on each icon in the set.
  iterate = (cb) ->
    _.each context.items, (item, id, itemset) ->
      cb.apply context, [item, id, itemset]

  # run a callback on each icon in the set and pass the item / icon as parameters to
  # the callback
  shiftStatus = (fn) ->
    iterate (item, id) ->
      status = fn.call(context, id, item, context.items)
      visChange = setVisibility(item, status is false)
      statusChange = false
      if status is `undefined`
        #do nothing
      else if status is false
        item.status = `undefined`
      else if item.status isnt status
        item._prevStatus = status
        item.status = status
        statusChange = true
      context.shiftMapItemStatus item, id  if statusChange or visChange
    context.statusShiftDone()

  all = -> _.values context.items

  # Set a given callback for NMIS.IconSwitcher
  setCallback = (cbName, cb) ->
    context[cbName] = cb  if callbacks.indexOf(cbName) isnt -1

  # Filter all the icons of items with a given status
  filterStatus = (status) ->
    _.filter context.items, (item) ->
      item.status is status

  # filter all the icons of items without a given status
  filterStatusNot = (status) ->
    _.filter context.items, (item) ->
      item.status isnt status

  allShowing = -> filterStatusNot `undefined`

  createAll = -> iterate context.createMapItem

  clear = -> context = {}

  # NMIS.IconSwitcher:
  init: init
  clear: clear
  allShowing: allShowing
  createAll: createAll
  filterStatus: filterStatus
  filterStatusNot: filterStatusNot
  all: all
  setCallback: setCallback
  shiftStatus: shiftStatus
  iterate: iterate

NMIS.FacilitySelector = do->
  ###
  NMIS.FacilitySelector handles actions that pertain to selecting a facility.

  Usage:
    NMIS.FacilitySelector.activate id: 1234
    NMIS.FacilitySelector.deselect()
    NMIS.FacilitySelector.isActive() #returns boolean
  ###
  active = false

  isActive = -> active
  activate = (params) ->
    fId = params.id
    NMIS.IconSwitcher.shiftStatus (id, item) ->
      if id isnt fId
        "background"
      else
        active = true
        "normal"
    facility = false
    lga = NMIS.Env().lga
    facility = val for key, val of lga.facilityData when key is params.id
    throw new Error("Facility with id #{params.id} is not found") unless facility

    NMIS.FacilityPopup facility
  deselect = ->
    if active
      sector = NMIS.activeSector()
      NMIS.IconSwitcher.shiftStatus (id, item) ->
        (if item.sector is sector then "normal" else "background")
      active = false
      dashboard.setLocation NMIS.urlFor(NMIS.Env.extend(facility: false))
      NMIS.FacilityPopup.hide()
  # Externally callable functions:
  activate: activate
  isActive: isActive
  deselect: deselect

# All JSON Queries are done through NMIS.DataLoader
# This ensures that we are using a consistent way to access the data
# repository.
NMIS.DataLoader = do ->
  ajaxJsonQuery = (url, cache=true)->
    $.ajax(url: url, dataType: "json", cache: cache)
  fetchLocalStorage = (url) ->
    p     =!1
    data  =!1
    stringData = localStorage.getItem(url)
    if stringData
      data = JSON.parse(stringData)
      ajaxJsonQuery(url).then (d)->
        localStorage.removeItem url
        localStorage.setItem url, JSON.stringify(d)

      $.Deferred().resolve [data]
    else
      p = new $.Deferred()
      ajaxJsonQuery(url).then (d)->
        localStorage.setItem url, JSON.stringify(d)
        p.resolve [d]
      p.promise()

  fetch = (url) -> ajaxJsonQuery url, false
  # Until localStorage fecthing works, just use $.getJSON
  fetch: fetch

NMIS.LocalNav = do ->
  # NMIS.LocalNav is the navigation boxes that shows up on top of the map.
  # > It has "buttonSections", each with buttons inside. These buttons are defined
  #   when they are passed as arguments to NMIS.LocalNav.init(...)
  #
  # > It is structured to make it easy to assign the buttons to point to URLs
  #   relative to the active LGA. It is also meant to be easy to change which
  #   buttons are active by passing values to NMIS.LocalNav.markActive(...)
  #
  #   An example value passed to markActive:
  #     NMIS.LocalNav.markActive(["mode:facilities", "sector:health"])
  #       ** this would "select" facilities and health **
  #
  # > You can also run NMIS.LocalNav.iterate to run through each button, changing
  #   the href to something appropriate given the current page state.
  # [wrapper element className: ".local-nav"]
  elem = undefined
  wrap = undefined
  opts = undefined
  buttonSections = {}
  submenu = undefined

  init = (selector, _opts) ->
    wrap = $(selector)
    opts = _.extend sections: [], _opts
    elem = $ "<ul />", id: "local-nav", class: "nav"
    wrap = $("<div />", class: "row ln-wrap")
      .css(position: "absolute", top: 82, left: 56, "z-index": 99)
      .html(elem)
    $(".content").eq(0).prepend wrap
    spacer = $("<li>", {class: "small spacer", html: "&nbsp;"})
    for section, i in opts.sections
      spacer.clone().appendTo(elem)  if i isnt 0
      for [id, text, url] in section
        arr = [id, text, url]
        [section_code, section_id] = id.split ":"
        buttonSections[section_code] = {} if buttonSections[section_code] is undefined
        a = $("<a>", href:url, text:text)
        buttonSections[section_code][section_id] = a
        $("<li>", html: a).appendTo(elem)
    submenu = $("<ul>", class: "submenu").appendTo(elem)

  hide = ()->
    wrap.detach()

  show = ()->
    if wrap.closest("html").length is 0
      $(".content").eq(0).prepend wrap

  getNavLink = (code) ->
    _x = code.split(":")
    section = _x[0]
    name = _x[1]
    buttonSections[section][name]
  markActive = (codesArray) ->
    wrap.find(".active").removeClass "active"
    _.each codesArray, (code) ->
      getNavLink(code).parents("li").eq(0).addClass "active"

  clear = ->
    wrap.empty()
    wrap = `undefined`
    elem = `undefined`
    buttonSections = {}
    submenu = `undefined`
  hideSubmenu = ->
    submenu.hide()
  displaySubmenu = (nlcode, a, _opts) ->
    navLink = getNavLink(nlcode)
    lpos = navLink.parents("li").eq(0).position().left
    submenu.hide().empty().css left: lpos
    _.each a, (aa) ->
      $("<li />").html($("<a />",
        text: aa[0]
        href: aa[1]
      )).appendTo submenu

    submenu.show()
  iterate = (cb) ->
    _.each buttonSections, (buttons, sectionName) ->
      _.each buttons, (button, buttonName) ->
        cb.apply this, [sectionName, buttonName, button]

  # NMIS.LocalNav:
  init: init
  clear: clear
  iterate: iterate
  hide: hide
  show: show
  displaySubmenu: displaySubmenu
  hideSubmenu: hideSubmenu
  markActive: markActive

do ->
  NMIS.Tabulation = do ->
    ###
    This is only currently used in the pie chart graphing of facility indicators.
    ###
    init = -> true
    filterBySector = (sector) ->
      sector = NMIS.Sectors.pluck(sector)
      _.filter NMIS.data(), (d) ->
        d.sector is sector

    sectorSlug = (sector, slug, keys) ->
      occurrences = {}
      values = _(filterBySector(sector)).chain().pluck(slug).map((v) ->
        "" + v
      ).value()
      keys = _.uniq(values).sort()  if keys is `undefined`
      _.each keys, (key) ->
        occurrences[key] = 0

      _.each values, (d) ->
        occurrences[d]++  if occurrences[d] isnt `undefined`

      occurrences
    sectorSlugAsArray = (sector, slug, keys) ->
      occurrences = sectorSlug.apply(this, arguments)
      keys = _.keys(occurrences).sort()  if keys is `undefined`
      _(keys).map (key) ->
        occurrences: "" + key
        value: occurrences[key]

    init: init
    sectorSlug: sectorSlug
    sectorSlugAsArray: sectorSlugAsArray

NMIS.Env = do ->
  # NMIS.Env() gets-or-sets the page state.
  #
  # It also provides the option to trigger callbacks which are run in a
  # special context upon each change of the page-state (each time NMIS.Env() is set)
  env = false
  changeCbs = []
  _latestChangeDeferred = false

  class EnvContext
    constructor: (@next, @prev)->
      # note: a promise object called "@change" will be assigned to each
      # EnvContext after it is created.

    usingSlug: (what, whatSlug)->
      # Usage: env.usingSlug("mode", "facilities") runs if the next env matches
      #        "mode:facilities"
      @_matchingSlug what, whatSlug

    changingToSlug: (what, whatSlug)->
      # Usage: env.changingToSlug("mode", "facilities") only runs if the previous env
      #        did not have "mode" match "facilities" but the next one does.
      # Output is equivalent to:
      #   @changing(what) and @usingSlug(what, whatSlug)
      !@_matchingSlug(what, whatSlug, false) and @_matchingSlug(what, whatSlug)

    changing: (what)->
      @_getSlug(what) isnt @_getSlug(what, false)

    changeDone: ()-> @_deferred?.resolve(@next)

    _matchingSlug: (what, whatSlug, checkNext=true)->
      # returns boolean of whether the environment matches a value
      @_getSlug(what, checkNext) is whatSlug

    _getSlug: (what, checkNext=true)->
      # returns a string that hopefully represents the slug of the environment variable
      checkEnv = if checkNext then @next else @prev
      obj = checkEnv[what]
      "#{if obj and obj.slug then obj.slug else obj}"

  env_accessor = (arg)->
    if arg?
      set_env arg
    else
      get_env()

  get_env = ()->
    if env
      _.extend {}, env
    else
      null

  set_env = (_env)->
    context = new EnvContext(_.extend({}, _env), env)
    context._deferred = _latestChangeDeferred = $.Deferred()
    context.change = _latestChangeDeferred.promise()
    env = context.next
    changeCb.call context, context.next, context.prev  for changeCb in changeCbs

  env_accessor.extend = (o)->
    e = if env then env else {}
    _.extend({}, e, o)

  env_accessor.onChange = (cb)->
    changeCbs.push cb

  env_accessor.changeDone = ()->
    # Use this (NMIS.Env.changeDone()) to resolve the most recent promise object
    _latestChangeDeferred.resolve env  if _latestChangeDeferred

  # NMIS.Env:
  env_accessor

NMIS.panels = do ->
  # NMIS.panels provides a basic way to define HTML DOM-related behavior when navigating from
  # one section of the site to another. (e.g. "summary" to "facilities".)
  panels = {}
  currentPanel = false

  class Panel
    constructor: (@id)->
      @_callbacks = {}
    addCallbacks: (obj={})->
      @addCallback name, cb  for own name, cb of obj
      @
    addCallback: (name, cb)->
      @_callbacks[name] = []  unless @_callbacks[name]
      @_callbacks[name].push cb
      @
    _triggerCallback: (name, nextPanel)->
      cb.call window, name, @, nextPanel  for cb in @_callbacks[name] or []
      @

  getPanel = (id)->
    panels[id] = new Panel id  if not panels[id]
    panels[id]

  changePanel = (id)->
    nextPanel = panels[id]
    if not nextPanel
      throw new Error "Panel not found: #{id}"
    else if nextPanel isnt currentPanel
      currentPanel._triggerCallback 'close', nextPanel  if currentPanel
      nextPanel._triggerCallback 'open', currentPanel
      currentPanel = nextPanel
      panels[id]
    else
      false

  ensurePanel = (id)->
    throw new Error "NMIS.panels.ensurePanel('#{id}') Error: Panel does not exist"  unless panels[id]

  getPanel: getPanel
  changePanel: changePanel
  ensurePanel: ensurePanel
  currentPanelId: ()-> currentPanel?.id
  allPanels: ()-> (v for k, v of panels)

do ->

  NMIS.DisplayWindow = do ->
    ###
    NMIS.DisplayWindow builds and provides access to the multi-part structure of
    the facilities view.
    ###
    elem = undefined
    elem1 = undefined
    elem0 = undefined
    elem1content = undefined
    opts = undefined
    visible = undefined
    hbuttons = undefined
    titleElems = {}
    curSize = undefined
    resizerSet = false
    resized = undefined
    curTitle = undefined
    initted = false
    contentWrap = false

    init = (_elem, _opts) ->
      initted = true
      clear()  if opts isnt `undefined`
      unless resizerSet
        resizerSet = true
        $(window).resize _.throttle resized, 1000
      contentWrap = $ _elem
      elem = $("<div />").appendTo contentWrap
      #default options:
      opts = _.extend(
        height: 100
        clickSizes: [["full", "Table Only"], ["middle", "Split"], ["minimized", "Map Only"]]
        size: "middle"
        sizeCookie: false
        callbacks: {}
        visible: false
        heights:
          full: Infinity
          middle: 280
          minimized: 46
        allowHide: true
        padding: 10
      , _opts)

      elem0 = $("<div />").addClass("elem0").appendTo(elem)
      elem1 = $("<div />").addClass("elem1").appendTo(elem)

      visible = !!opts.visible
      setVisibility visible, false

      opts.size = $.cookie("displayWindowSize") or opts.size  if opts.sizeCookie
      elem.addClass "display-window-wrap"
      elem1.addClass "display-window-content"
      createHeaderBar().appendTo elem1
      elem1content = $("<div />").addClass("elem1-content").appendTo(elem1)

      setSize opts.size

    setDWHeight = (height) ->
      if height is `undefined`
        height = "auto"
      else height = fullHeight()  if height is "calculate"
      elem.height height
      elem0.height height
    setTitle = (t, tt) ->
      _.each titleElems, (e) -> e.text t
      if tt isnt `undefined`
        $("head title").text "NMIS: " + tt
      else
        $("head title").text "NMIS: " + t
    showTitle = (i) ->
      curTitle = i
      _.each titleElems, (e, key) ->
        if key is i
          e.show()
        else
          e.hide()

    addCallback = (cbname, cb) ->
      opts.callbacks[cbname] = []  if opts.callbacks[cbname] is `undefined`
      opts.callbacks[cbname].push cb

    setBarHeight = (h, animate, cb) ->
      if animate
        elem1.animate
          height: h
        ,
          duration: 200
          complete: cb

      else
        elem1.css height: h
        (cb or ->
        )()

    setSize = (_size, animate) ->
      size = undefined
      if opts.heights[_size] isnt `undefined`
        size = opts.heights[_size]
        size = fullHeight()  if size is Infinity
        $.cookie "displayWindowSize", _size
        setBarHeight size, animate, ->
          elem1.removeClass "size-" + curSize  unless not curSize
          elem1.addClass "size-" + _size
          curSize = _size

      if opts.callbacks[_size] isnt `undefined`
        _.each opts.callbacks[_size], (cb) ->
          cb animate

      if opts.callbacks.resize isnt `undefined`
        _.each opts.callbacks.resize, (cb) ->
          cb animate, _size, elem, elem1, elem1content

      hbuttons.find(".primary").removeClass "primary"
      hbuttons.find(".clicksize." + _size).addClass "primary"

    setVisibility = (tf) ->
      css = {}
      visible = !!tf
      unless visible
        css =
          left: "1000em"
          display: "none"
      else
        css =
          left: "0"
          display: "block"
      elem0.css css
      elem1.css css

    ensureInitialized = ()-> throw new Error("NMIS.DisplayWindow is not initialized") unless initted

    hide = ()->
      setVisibility false
      ensureInitialized()
      elem.detach()
    show = ()->
      setVisibility true
      ensureInitialized()
      unless elem.inDom()
        contentWrap.append elem
    addTitle = (key, jqElem) ->
      titleElems[key] = jqElem
      showTitle key  if curTitle is key
    createHeaderBar = ->
      hbuttons = $("<span />") #.addClass('print-hide-inline');
      _.each opts.clickSizes, ([size, desc]) ->
        $("<a />").attr("class", "btn small clicksize #{size}")
            .text(desc)
            .attr("title", desc)
            .click(-> setSize(size, false))
            .appendTo hbuttons

      titleElems.bar = $("<h3 />").addClass("bar-title").hide()
      $("<div />", class: "display-window-bar breadcrumb")
          .css(margin: 0)
          .append(titleElems.bar)
          .append hbuttons

    clear = ->
      elem isnt `undefined` and elem.empty()
      titleElems = {}

    getElems = ->
      wrap: elem
      elem0: elem0
      elem1: elem1
      elem1content: elem1content

    fullHeight = ->
      # gets the available height of the DisplayWindow wrap (everything except the header.)
      oh = 0
      $(opts.offsetElems).each -> oh += $(this).height()
      $(window).height() - oh - opts.padding

    elem1contentHeight = ->
      padding = 30
      elem1.height() - hbuttons.height() - padding

    resized = ->
      # this function is throttled
      if visible and curSize isnt "full"
        fh = fullHeight()
        elem.stop true, false
        elem.animate height: fh
        elem0.stop true, false
        elem0.animate height: fh

    init: init
    clear: clear
    setSize: setSize
    getSize: ->
      curSize

    setVisibility: setVisibility
    hide: hide
    show: show
    addCallback: addCallback
    setDWHeight: setDWHeight
    addTitle: addTitle
    setTitle: setTitle
    showTitle: showTitle
    elem1contentHeight: elem1contentHeight
    getElems: getElems
# begin b_country_view.coffee
do ->
  loadMapLayers = ()->
    if NMIS._mapLayersModule_?
      NMIS._mapLayersModule_.fetch()
    else
      dfd = $.Deferred()
      dfd.reject "map_layers not found"
      dfd.promise()

  do ->
    activateNavigation = (wrap)->
      navId = "#zone-navigation"
      unless wrap.hasClass("zone-nav-activated")
        wrap.on "click", "#{navId} a.state-link", (evt)->
          ul = $(@).parents("li").eq(0).find("ul")
          isShowing = ul.hasClass "showing"
          wrap.find("#{navId} .showing").removeClass("showing")
          ul.addClass "showing" unless isShowing
          false
      wrap.addClass "zone-nav-activated"

    cvp = false
    countryViewPanel = ()->
      wrap = $(".content")
      unless cvp
        cvp = $("<div>", class: "country-view")
        activateNavigation wrap
      if cvp.closest("html").length is 0
        cvp.appendTo(".content")
      cvp

    panelOpen = ()->
      NMIS.LocalNav.hide()
      NMIS.Breadcrumb.clear()
      NMIS.Breadcrumb.setLevels [["Country View", "/"]]
      data =
        title: "Nigeria"
        zones: NMIS._zones_
      countryViewPanel().html $._template "#country-view-tmpl", data
      # cvp.find("#map").hide()

    panelClose = ()->
      countryViewPanel().detach()

    NMIS.panels.getPanel("country_view").addCallbacks open: panelOpen, close: panelClose

  NMIS.MainMdgMap = do ->
    mdgLayers = []
    baseLayer = false

    launchCountryMapInElem = (eselector)->
      layerIdsAndNames = []
      $elem = $(eselector).css width: 680, height: 476, position: 'absolute'
      launcher = NMIS.loadLeaflet()
      launcher.done ()->
        $(".map-loading-message").hide()
        elem = $elem.get(0)
        mapId = "nmis-ol-country-map"
        $elem.prop 'id', mapId
        centroid =
          lat: 9.16718
          lng: 7.53662
        sw = new L.LatLng 3.9738609758391017, 0.06591796875
        ne = new L.LatLng 14.28567730018259, 15.00732421875
        country_bounds = new L.LatLngBounds sw, ne
        lmap = L.map(mapId,
          maxZoom: 11
          minZoom: 6
          maxBounds: country_bounds
        ).setView [centroid.lat, centroid.lng], 6
        window.lmap = lmap
        attribution = '&copy; <a href="http://osm.org/copyright">OpenStreetMap</a> contributors'
        baseLayer = L.tileLayer("http://b.tiles.mapbox.com/v3/modilabs.nigeria_base/{z}/{x}/{y}.png",attribution: attribution).addTo lmap
        mapLayers = {}
        for mdgL in mdgLayers
          do ->
            curMdgL = mdgL
            tileset = mdgL.slug
            attribution = "modilabs"
            ml = L.tileLayer "http://a.tiles.mapbox.com/v3/modilabs.{tileset}/{z}/{x}/{y}.png",
                attribution: attribution
                tileset: mdgL.slug

            curMdgL.onSelect = ()->
              lmap.removeLayer baseLayer
              lmap.addLayer(ml)
              @show_description()
      launcher.fail ()->
        log "LAUNCHER FAIL! Scripts not loaded"

    createLayerSwitcher = do ->
      layersWitoutMdg = []
      layersByMdg = {}
      mdgs = []
      sb = false
      layersBySlug = {}
      plsSelectMsg = "Please select an indicator map..."

      class MDGLayer
        constructor: ({@data_source, @description, @display_order,
                        @sector_string, @mdg, @slug, @legend_data,
                        @indicator_key, @level_key, @id, @name})->
          mdgLayers.push @
          layersBySlug[@slug] = @
          mdgs.push @mdg unless @mdg in mdgs
          if @mdg
            layersByMdg[@mdg] = []  unless layersByMdg[@mdg]
            layersByMdg[@mdg].push @
          else
            layersWitoutMdg.push @

        show_description: ->
          descWrap = $(".mn-iiwrap")
          goalText = NMIS.mdgGoalText(@mdg)
          descWrap.find(".mdg-display").html goalText
          descWrap.find("div.layer-description").html $("<p>", text: @description)
        $option: ->
          $ "<option>", value: @slug, text: @name

      onSelect: ()->
      selectBoxChange = ()->
        layersBySlug[$(@).val()].onSelect()

      createSelectBox = ->
        sb = $ "<select>", title: plsSelectMsg, style: "width:100%", change: selectBoxChange
        for mdg in mdgs.sort() when mdg?
          sb.append og = $ "<optgroup>", label: "MDG #{mdg}"
          og.append layer.$option()  for layer in layersByMdg[mdg]
        sb

      (mlData, selectBoxWrap)->
        new MDGLayer mld  for mld in mlData
        selectBoxWrap.html(createSelectBox()).children().chosen()

    launchCountryMapInElem: launchCountryMapInElem
    createLayerSwitcher: createLayerSwitcher

  do ->
    NMIS.mdgGoalText = (gn)->
      [
        "Goal 1 &raquo; Eradicate extreme poverty and hunger",
        "Goal 2 &raquo; Achieve universal primary education",
        "Goal 3 &raquo; Promote gender equality and empower women",
        "Goal 4 &raquo; Reduce child mortality rates",
        "Goal 5 &raquo; Improve maternal health",
        "Goal 6 &raquo; Combat HIV/AIDS, malaria, and other diseases",
        "Goal 7 &raquo; Ensure environmental sustainability",
        "Goal 8 &raquo; Develop a global partnership for development"
      ][gn-1]

  do ->
    NMIS.CountryView = ()->
      NMIS.panels.changePanel "country_view"
      NMIS.Env {}
      ml = loadMapLayers()
      ml.done (mlData)->
        $(".resizing-map").show()
        mdgLayerSelectBox = $(".layer-nav")
        NMIS.MainMdgMap.createLayerSwitcher mlData, mdgLayerSelectBox
        NMIS.MainMdgMap.launchCountryMapInElem ".home-map", mlData
      ml.fail (msg)->
        $(".resizing-map").hide()
# begin b_districts.coffee
do ->
  headers = do ->
    header = false
    nav = false
    (what)->
      if what is "header"
        if !header
          header = $('.data-src').on 'click', 'a', ()-> false
        else
          header
      else if what is "nav"
        if !nav
          nav = $('.lga-nav').on 'submit', 'form', (evt)->
            d = NMIS.findDistrictById nav.find('select').val()
            dashboard.setLocation NMIS.urlFor.extendEnv state: d.group, lga: d
            evt.preventDefault()
            return false
        else
          nav

  do ->
    display_in_header = (s)->
      title = s.title
      $('title').html(title)
      brand = $('.brand')
      logo = brand.find('.logo').detach()
      brand.empty().append(logo).append(title)
      headers('header').find("span").text(s.id)

    district_select = false

    ### NMIS.load_districts should be moved here. ###
    load_districts = (group_list, district_list)->
      group_names = []
      groups = []

      get_group_by_id = (grp_id)->
        grp_found = false
        grp_found = grp for grp in groups when grp.id is grp_id
        grp_found

      groups = (new NMIS.Group(grp_details) for grp_details in group_list)

      districts = for district in district_list
        d = new NMIS.District district
        d.set_group get_group_by_id d.group
        d

      groupsObj = {}
      groupsObj[g.id] = g  for g in groups
      group.assignParentGroup groupsObj  for group in groups
      group.assignLevel() for group in groups

      zones = []
      states = []

      for g in groups
        if g.group is undefined
          zones.push g
        else
          states.push g

      NMIS._zones_ = zones.sort (a, b)-> a.label > b.label if b?
      NMIS._states_ = states.sort (a, b)-> a.label > b.label if b?

      new_select = $ '<select>', id: 'lga-select', title: 'Select a district'
      for group in groups
        optgroup = $ '<optgroup>', label: group.label
        optgroup.append $ '<option>', d.html_params for d in group.districts
        new_select.append optgroup

      ###
      We will want to hang on to these districts for later, and give them
      a nice name when we find a good home for them.
      ###
      NMIS._districts_ = districts
      NMIS._groups_ = groups

      # already_selected = $.cookie "selected-district"
      # if already_selected?
      #   new_select.val already_selected
      #   NMIS.select_district already_selected

      submit_button = headers('nav').find("input[type='submit']").detach()
      headers('nav').find('form div').eq(0).empty().html(new_select).append(submit_button)
      district_select = new_select.chosen()

    NMIS.districtDropdownSelect = (district=false)->
      if district and district_select
        district_select.val(district.id).trigger "liszt:updated"

    NMIS.load_schema = (data_src)->
      schema_url = "#{data_src}schema.json"
      deferred = new $.Deferred
      # Change root url of logo to the root url of the dashboard.
      $("a.brand").attr "href", NMIS.url_root
      getSchema = $.ajax(url: schema_url, dataType: "json", cache: false)
      getSchema.done (schema)->
        display_in_header schema
        NMIS._mapLayersModule_ = new Module "Map Layers", schema.map_layers  if schema.map_layers
        Module.DEFAULT_MODULES = (new Module(dname, durl) for dname, durl of schema.defaults)

        if schema.districts? and schema.groups?
          load_districts schema.groups, schema.districts
          deferred.resolve()
        else
          districts_module = do ->
            for mf in Module.DEFAULT_MODULES when mf.name is "geo/districts"
              return mf
          districts_module.fetch().done ({groups, districts})->
            load_districts groups, districts
            deferred.resolve()
      getSchema.fail (e)-> deferred.reject "Schema file not loaded"
      deferred.promise()

  do ->
    NMIS.findDistrictById = (district_id=false)->
      ###
      this is called on form submit, for example
      ###
      existing = false
      if district_id
        existing = d for d in NMIS._districts_ when d.id is district_id
      # $.cookie "selected-district", if existing then district_id else ""
      # if existing
      #   NMIS._lgaFacilitiesDataUrl_ = "#{existing.data_root}/facilities.json"
      #   dashboard.setLocation NMIS.urlFor state: existing.group.slug, lga: existing.slug
      existing

  class NMIS.DataRecord
    constructor: (@lga, obj)->
      @value = obj.value
      @source = obj.source
      @id = obj.id

    displayValue: ->
      variable = @variable()
      if variable.data_type is "percent"
        value = NMIS.DisplayValue.raw(@value * 100, variable)[0]
        "#{value}%"
      else
        value = NMIS.DisplayValue.raw(@value)[0]
        value

    variable: ->
      @lga.variableSet.find @id

  class NoOpFetch
    constructor: (@id)->
    fetch: ()->
      dfd = new $.Deferred()
      cb = ()->
        msg = "#{@id} messed up."
        dfd.reject(msg)
      window.setTimeout cb, 500
      dfd.fail ()=> console.error("failure: #{@id}")
      dfd.promise()

  class NMIS.District
    constructor: (d)->
      _.extend @, d
      @name = @label unless @name
      @active = !!d.active
      [@group_slug, @slug] = d.url_code.split("/")
      @files = [] unless @files?
      @module_files = (new Module(slug, f_param, @) for slug, f_param of @files)
      @_fetchesInProgress = {}
      @latLng = @lat_lng
      @sector_gap_sheets = d.sector_gap_sheets || {}
      @id = [@group_slug, @local_id].join("_")
      @html_params =
        text: @name
        value: @id
      @html_params.disabled = "disabled"  unless @active
    llArr: ->
      +coord for coord in @latLng.split ","
    latLngBounds: ()->
      if !@_latLngBounds and @bounds
        @_latLngBounds = @bounds.split /\s|,/
      else if !@_latLngBounds
        log """
        Approximating district lat-lng bounds. You can set district's bounding box in districts.json by
        setting the value of "bounds" to comma separated coordinates.
        Format: "SW-lat,SW-lng,NE-lat,NE-lng"
        Example: "6.645,7.612,6.84,7.762"
        """
        # small padding on lat and lng to create an estimated bounding box.
        # note: this is not meant to be accurate. The best way to actually 
        # zoom to the district is to specify the bounding box.
        smallLat = 0.075
        smallLng = 0.1
        [lat, lng] = @llArr()
        @_latLngBounds = [lat - smallLat, lng - smallLng, lat + smallLat, lng + smallLng]
      @_latLngBounds
    defaultSammyUrl: ()->
      "#{NMIS.url_root}#/#{@group_slug}/#{@slug}/summary"

    get_data_module: (module)->
      for mf in @module_files when mf.name is module
        return mf
      for mf in Module.DEFAULT_MODULES when mf.name is module
        return mf
      throw new Error("Module not found: #{module}")
      # new NoOpFetch(module)
      # match = m for m in @module_files when m.name is module
      # unless match?
      #   # log "GETTING DEFAULT #{module}", DEFAULT_MODULES, module in DEFAULT_MODULES
      #   match = Module.DEFAULT_MODULES[module]
      # throw new Error("Module not found: #{module}") unless match?
      # match

    has_data_module: (module)->
      try
        !!@get_data_module module
      catch e
        false

    _fetchModuleOnce: (resultAttribute, moduleId, cb=false)->
      if @[resultAttribute]
        # the result's already there so this returns a resolved promise
        $.Deferred().resolve().promise()
      else if @_fetchesInProgress[resultAttribute]
        # the previous fetch is still in progress so this returns that promise obj
        @_fetchesInProgress[resultAttribute]
      else
        # no previous fetch, so this returns a new fetch.
        dfd = $.Deferred()
        @get_data_module(moduleId).fetch().done (results)=>
          @[resultAttribute] = if cb then cb(results) else results
          dfd.resolve()
        @_fetchesInProgress[resultAttribute] = dfd.promise()

    sectors_data_loader: ->
      # TODO: use "sectors" associated with this LGA instead of global NMIS sectors.
      @_fetchModuleOnce "__sectors_TODO", "presentation/sectors", (results)=>
        NMIS.loadSectors results.sectors,
          default:
            name: "overview"
            slug: "overview"

    loadFacilitiesData: ()->
      @_fetchModuleOnce "facilityData", "data/facilities", (results)=>
        # NMIS.loadFacilities will be removed soon
        NMIS.loadFacilities results

        # this replicates the functionality of NMIS.loadFacilities, but stores
        # the results with the specific LGA.
        clonedFacilitiesById = {}
        for own facKey, fac of results
          datum = {}

          # Clone fac into datum:
          # handle special cases: "gps" -> _ll. "sector",
          # and cast boolean strings to bools.
          for own key, val of fac
            if key is "gps"
              datum._ll = do ->
                if val and ll = val.split?(" ")
                  [ll[0], ll[1]]
            else if key is "sector"
              datum.sector = NMIS.Sectors.pluck val.toLowerCase()
            else
              if _.isString(val)
                if val.match /^true$/i
                  val = true
                else if val.match /^false$/i
                  val = false
                else if val is "" or val.match /^na$/i
                  val = `undefined`
                else
                  if !val.match(/[a-zA-Z]/) and !isNaN (parsedMatch = parseFloat val)
                    val = parsedMatch
              datum[key] = val
          datum.id = fac._id or fac.X_id or facKey  unless datum.id
          unless datum.sector
            log "No sector for datum", datum
          clonedFacilitiesById[datum.id] = datum
        clonedFacilitiesById

    facilityDataForSector: (sectorSlug)->
      facilities = []
      for own facId, fac of @facilityData
        if fac.sector is undefined
          log "No sector:", fac
          throw new Error("Facility does not have a sector")
        else if fac.sector.slug is sectorSlug
          facilities.push fac
      facilities

    loadData: ()->
      @_fetchModuleOnce "lga_data", "data/lga_data", (results)=>
        arr = []
        if results.data
          arr = results.data
        else if results.length is 1
          # To allow data to be passed in the format that bamboo gives it to us.
          # assuming if results.length is 1 means the data is organized in two wide rows
          # with many columns rather than many rows and 2 columns
          for own key, val of results[0]
            arr.push id: key, value: val
        else
          arr = results
        for d in arr
          new NMIS.DataRecord @, d

    loadVariables: ()->
      @_fetchModuleOnce "variableSet", "variables/variables", (results)=>
        new NMIS.VariableSet results

    loadFacilitiesPresentation: ()->
      @_fetchModuleOnce "facilitiesPresentation", "presentation/facilities"

    loadSummarySectors: ()->
      @_fetchModuleOnce "ssData", "presentation/summary_sectors"

    lookupRecord: (id)->
      matches = []
      matches.push datum  for datum in @lga_data when datum.id is id
      matches[0]

    set_group: (@group)-> @group.add_district @

  NMIS.getDistrictByUrlCode = (url_code)->
    matching_district = false
    matching_district = d for d in NMIS._districts_ when d.url_code is url_code
    throw new Error "District: #{url_code} not found" unless matching_district
    matching_district

  class NMIS.Group
    constructor: (details)->
      @districts = []
      @name = @label = details.label
      @id = details.id
      @groupId = details.group
      @children = []
    add_district: (d)->
      @districts.push d
      @children.push d
      @slug = d.group_slug unless @slug?
      @districts = @districts.sort (a, b)-> a.label > b.label if b?
      @children = @children.sort (a, b)-> a.label > b.label if b?
      true
    activeDistrictsCount: ->
      i = 0
      i++  for district in @districts when district.active
      i
    assignParentGroup: (allGroups)->
      if @groupId and allGroups[@groupId]
        @group = allGroups[@groupId]
        @group.children.push @
    assignLevel: ()->
      @_level = @ancestors().length - 1
    ancestors: ()->
      ps = []
      g = @
      while g isnt undefined
        ps.push g
        g = g.group
      ps

  class Module
    @DEFAULT_MODULES = []
    constructor: (@id, file_param, district)->
      if _.isArray(file_param)
        @files = (new ModuleFile(fp, district) for fp in file_param)
      else
        @filename = file_param
        @files = [new ModuleFile(file_param, district)]
      @name = @id
    fetch: ()->
      if @files.length > 1
        dfd = $.Deferred()
        $.when.apply(null, (f.fetch() for f in @files)).done (args...)->
          dfd.resolve Array::concat.apply [], args
        dfd.promise()
      else if @files.length is 1
        @files[0].fetch()

  csv.settings.parseFloat = false

  class ModuleFile
    constructor: (@filename, @district)->
      try
        [devnull, @name, @file_type] = @filename.match(/(.*)\.(json|csv)/)
      catch e
        throw new Error("ModuleFile Filetype not recognized: #{@filename}")
      mid_url = if @district? then "#{@district.data_root}/" else ""
      if @filename.match(/^https?:/)
        @url = @filename
      else
        @url = "#{NMIS._data_src_root_url}#{mid_url}#{@filename}"
    fetch: ()->
      if /\.csv$/.test @url
        # load CSV
        dfd = $.Deferred()
        $.ajax(url: @url).done (results)->
          dfd.resolve csv(results).toObjects()
        dfd
      else if /\.json$/.test @url
        # load JSON
        NMIS.DataLoader.fetch @url
      else
        throw new Error("Unknown action")
# begin b_facility_tables.coffee

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
# begin b_sectors.coffee
do ->
  sectors = null
  defaultSector = null

  class DistrictSectors
    constructor: (@district, _sectors, opts={})->
      @defaultSector = new Sector(_.extend(opts["default"], default: true))  if opts.default
      @sectors = _(_sectors).chain().clone().map((s) -> new Sector(_.extend({}, s))).value()

  class Sector
    constructor: (d)->
      # "extend" d onto this object but prepend underscore to certain keys
      changed_keys = "subgroups columns default".split ' '
      @[if k in changed_keys then "_#{k}" else k] = val  for k, val of d

    subGroups: ()-> if @_subgroups? then @_subgroups else []
    subSectors: @::subGroups
    
    getColumns: ()->
      return [] if !@_columns
      @_columns.sort (a, b)-> if a.display_order > b.display_order then 1 else -1

    columnsInSubGroup: (sgSlug)->
      _.filter @getColumns(), (sg) -> !!_.find(sg.subgroups, (f) -> f is sgSlug)

    getIndicators: -> @_columns or []
    isDefault: -> !!@_default

    getSubsector: (query) ->
      return  unless query
      ssSlug = query.slug or query
      ssI = 0
      ss = @subSectors()
      ssL = ss.length
      while ssI < ssL
        return new SubSector(this, ss[ssI])  if ss[ssI].slug is ssSlug
        ssI++

    getIndicator: (query) ->
      return  unless query
      islug = query.slug or query
      return new Indicator(@, indicator) if indicator.slug is islug for indicator in @getIndicators()

  class SubSector
    constructor: (@sector, opts) -> @[k] = val  for k, val of opts

    columns: ()->
      matches = []
      matches.push t for tt in t.subgroups when tt is @slug for t in @sector.getColumns()
      matches

  class Indicator
    constructor: (@sector, opts) -> @[k] = val  for own k, val of opts
    customIconForItem: (item)->
      ["#{NMIS.settings.pathToMapIcons}/#{@iconify_png_url}#{item[@slug]}.png", 32, 24]

  init = (_sectors, opts) ->
    if !!opts and !!opts["default"]
      defaultSector = new Sector(_.extend(opts["default"], default: true))
    sectors = _(_sectors).chain().clone().map((s) -> new Sector(_.extend({}, s))).value()
    true

  loadForDistrict = (district, data)->
    district.sectors = new DistrictSectors(district, data)

  clear = -> sectors = []
  pluck = (slugOrObj, defaultIfNoMatch=true) ->
    if slugOrObj
      slug = if slugOrObj.slug? then slugOrObj.slug else slugOrObj
      sectorMatch = sector  for sector in sectors when sector.slug is slug
    unless defaultIfNoMatch then sectorMatch else sectorMatch or defaultSector

  all = -> sectors
  validate = ->
    warn "Sectors must be defined as an array"  if not sectors instanceof Array
    warn "Sectors array is empty"  if sectors.length is 0
    _.each sectors, (sector) ->
      warn "Sector name must be defined."  if sector.name is `undefined`
      warn "Sector slug must be defined."  if sector.slug is `undefined`

    slugs = _(sectors).pluck("slug")
    warn "Sector slugs must not be reused"  if slugs.length isnt _(slugs).uniq().length
    true
  slugs = ->
    _.pluck sectors, "slug"

  NMIS.Sectors =
    init: init
    loadForDistrict: loadForDistrict
    pluck: pluck
    slugs: slugs
    all: all
    validate: validate
    clear: clear

# begin c_launch_open_layers.coffee
do ->
  NMIS.loadGoogleMaps = do ->
    loadStarted = false
    googleMapsDfd = $.Deferred()

    window.googleMapsLoaded = ()->
      if google?.maps?
        googleMapsDfd.resolve google.maps
      else
        googleMapsDfd.reject {}, "error", "Failed to load Google Maps"

    ()->
      unless loadStarted
        loadStarted = true
        s = document.createElement "script"
        s.src = "http://maps.googleapis.com/maps/api/js?sensor=false&callback=googleMapsLoaded"
        document.body.appendChild s
      googleMapsDfd.promise()

  NMIS.loadOpenLayers = (url)->
    url = "#{NMIS.settings.openLayersRoot}OpenLayers.js" if !url and NMIS.settings.openLayersRoot
    $.ajax url: url, dataType: "script", cache: false

  NMIS.loadLeaflet = (url)->
    url = "#{NMIS.settings.leafletRoot}leaflet.js" if !url and NMIS.settings.leafletRoot
    $.ajax url: url, dataType: "script", cache: false

  NMIS.loadGmapsAndOpenlayers = do ->
    launchDfd = $.Deferred()
    scriptsStarted = false
    () ->
      unless scriptsStarted
        scriptsStarted = true
        gmLoad = NMIS.loadGoogleMaps()
        gmLoad.done (gmaps)->
          olLoad = NMIS.loadOpenLayers()
          olLoad.done (ol)->
            launchDfd.resolve()
          olLoad.fail (o, err, message)-> launchDfd.reject o, err, message
        gmLoad.fail (o, err, message)-> launchDfd.reject o, err, message
      launchDfd.promise()

  NMIS.loadGmapsAndLeaflet = do ->
    launchDfd = $.Deferred()
    scriptsStarted = false
    () ->
      unless scriptsStarted
        scriptsStarted = true
        gmLoad = NMIS.loadGoogleMaps()
        gmLoad.done (gmaps)->
          llLoad = NMIS.loadLeaflet()
          llLoad.done (ol)->
            launchDfd.resolve()
          lllLoad.fail (l, err, message)-> launchDfd.reject l, err, message
        gmLoad.fail (o, err, message)-> launchDfd.reject o, err, message
      launchDfd.promise()

# begin c_variables.coffee
do ->
  variablesById = {}

  class Variable
    constructor: (v)->
      id = v.id || v.slug
      @id     = id
      @name   = v.name
      @data_type = v.data_type || "float"
      @precision = v.precision || 1
      @context = v.context || {}
    lookup: (what, context=false)->
      result = @[what]
      result = @context[context][what]  if @context[context]?[what]
      result

  class NMIS.VariableSet
    constructor: (variables)->
      log "created new variable set for lga"
      @variablesById = {}
      list = variables.list
      for v in list
        vrb = new Variable v
        @variablesById[vrb.id] = vrb  if vrb.id

    ids: ()->
      key for key, val of @variablesById

    find: (id)-> @variablesById[id]

  # NMIS.variables is obsolete. It can be removed.
  NMIS.variables = do ->
    clear = ()->
      
    load = (variables)->
      list = variables.list
      for v in list
        vrb = new Variable v
        variablesById[vrb.id] = vrb  if vrb.id

    ids = ->
      key for key, val of variablesById

    find = (id)-> variablesById[id]

    load: load
    clear: clear
    ids: ids
    find: find
# begin facilities.coffee

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

do ->
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
# begin popups_and_hovers.coffee

do ->

  # These bits are kinda beastly.
  # we might want to clean them up.
  _getNameFromFacility = (f) -> f.name or f.facility_name or f.school_name

  NMIS.FacilityHover = do ->
    hoverOverlayWrap = undefined
    hoverOverlay = undefined
    wh = 90

    getPixelOffset = (marker, map) ->
      scale = Math.pow(2, map.getZoom())
      nw = new google.maps.LatLng(map.getBounds().getNorthEast().lat(), map.getBounds().getSouthWest().lng())
      worldCoordinateNW = map.getProjection().fromLatLngToPoint(nw)
      worldCoordinate = map.getProjection().fromLatLngToPoint(marker.getPosition())
      pixelOffset = new google.maps.Point(Math.floor((worldCoordinate.x - worldCoordinateNW.x) * scale), Math.floor((worldCoordinate.y - worldCoordinateNW.y) * scale))

    show = (marker, opts) ->
      opts = {}  if opts is `undefined`
      map = marker.map
      opts.insertBefore = map.getDiv()  unless opts.insertBefore
      unless hoverOverlayWrap
        hoverOverlayWrap = $("<div />").addClass("hover-overlay-wrap")
        hoverOverlayWrap.insertBefore opts.insertBefore
      opts.pOffset = getPixelOffset(marker, map)  unless opts.pOffset
      opts.item = marker.nmis.item  unless opts.item
      opts.item.s3_photo_id = "none:none"  unless opts.item.s3_photo_id
      obj =
        top: opts.pOffset.y + 10
        left: opts.pOffset.x - 25
        arrowLeft: 22
        name: _getNameFromFacility(opts.item)
        community: opts.item.community
        title: opts.item.id
        img_thumb: NMIS.S3orFormhubPhotoUrl(opts.item, 200)

      hoverOverlay = $ $._template("#facility-hover", obj)
      hoverOverlay.addClass opts.addClass  unless not opts.addClass
      img = $("<img />").load(->
        $this = $(this)
        if $this.width() > $this.height()
          $this.width wh
        else
          $this.height wh
        $this.css
          marginTop: -.5 * $this.height()
          marginLeft: -.5 * $this.width()

      ).attr("src", NMIS.S3orFormhubPhotoUrl(opts.item, 90))
      hoverOverlay.find("div.photothumb").html img
      hoverOverlayWrap.html hoverOverlay
    hide = (delay) -> hoverOverlay.hide()  unless not hoverOverlay
    show: show
    hide: hide

  NMIS.FacilityPopup = do ->
    div = undefined

    facility_popup = (facility, opts) ->
      opts = {}  if opts is `undefined`
      div.remove()  unless not div
      obj = _.extend(
        thumbnail_url: ->
          NMIS.S3orFormhubPhotoUrl @, 200

        image_url: ->
          NMIS.S3orFormhubPhotoUrl @, "0"

        name: _getNameFromFacility(facility)
      , facility)
      subgroups = facility.sector.subGroups()
      defaultSubgroup = subgroups[0]
      obj.sector_data = _.map(subgroups, (o, i, arr) ->
        _.extend {}, o,
          variables: _.map(facility.sector.columnsInSubGroup(o.slug), (oo, ii, oiarr) ->
            NMIS.DisplayValue.special facility[oo.slug], oo
          )
      )
      tmplHtml = $._template("#facility-popup", obj)
      div = $(tmplHtml)
      s = div.find("select")
      sdiv = div.find(".fac-content")
      showDataForSector = ((slug) ->
        sdiv.find("> div").hide().filter((d, dd) ->
          $(dd).data("sectorSlug") is slug
        ).show()
      )
      showDataForSector defaultSubgroup.slug
      s.change ->
        showDataForSector $(this).val()

      div.addClass "fac-popup"
      div.dialog
        width: 500
        height: 300
        resizable: false
        close: -> NMIS.FacilitySelector.deselect()

      div.addClass opts.addClass  unless not opts.addClass
      div

    facility_popup.hide = ->
      $(".fac-popup").remove()

    facility_popup

# begin summary.coffee

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

do ->
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
        summaryMap.setCenter new google.maps.LatLng(ll[0], ll[1]), mapZoom

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
          spanStr = (content="&mdash;", cls="")->
            "<span class='#{cls}' style='text-transform:none'>#{content}</span>"

          displayPanels.start()
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
          if displayPanels.get(module)?
            panel = displayPanels.get(module)
            panel.build div, context
          else
            div.html template_not_found(module)
          div
        sector_window_inner_wrap.append sectorPanel
      sector_window.appendTo cc_div
    cc_div

  displayPanels = do ->
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
    start: establish_template_display_panels
    get: (x)-> __display_panels[x]

  # identical to _.delay except switches the order of the parameters
  _rDelay = (i, fn)-> _.delay fn, i


# begin dashboard.coffee

do ->
  #  initializing a Sammy.js object, called "dashboard".
  #  This will route URLs and handle links to pre-routed URLs.
  #  
  #  routes are defined in nmis_facilities.js and nmis_summary.js by:
  #     dashboard.get("/url/:variable", callback);
  #  
  #  URL actions can be triggered by calling:
  #     dashboard.setLocation("/url/hello");
  #  

  #
  #      If the url has a search string that includes "?data=xyz", then this
  #      will assign the data-source cookie to the value and then redirect to
  #      the URL without the data-source in it.
  #    

  NMIS.settings =
    openLayersRoot: "/static/openlayers/"
    leafletRoot: "/static/leaflet/"
    pathToMapIcons: "/static/images"

  NMIS.url_root = do ->
    url_root = "#{window.location.pathname}"
    url_root = url_root.replace("index.html", "")  unless not ~url_root.indexOf("index.html")
    url_root

  @dashboard = $.sammy("body", ->
    @get "" + NMIS.url_root + "#/:state/:lga/?", ->
      redirect = undefined
      _this = this
      redirect = ->
        dashboard.setLocation "" + NMIS.url_root + "#/" + _this.params.state + "/" + _this.params.lga + "/summary"

      _.delay redirect, 500

  )
  NMIS.DisplayWindow.init ".content",
    offsetElems: ".topbar .fill .container"
    sizeCookie: true

  overviewObj =
    name: "Overview"
    slug: "overview"

  NMIS.init()
  wElems = NMIS.DisplayWindow.getElems()
  NMIS._wElems = wElems
  NMIS.LocalNav.init wElems.wrap,
    sections: [[["mode:summary", "LGA Summary", "#"], ["mode:facilities", "Facility Detail", "#"]], [["sector:overview", "Overview", "#"], ["sector:health", "Health", "#"], ["sector:education", "Education", "#"], ["sector:water", "Water", "#"]]]

  NMIS.LocalNav.hide()
  do ->
    pushAsDefined = undefined
    urlFor = undefined
    pushAsDefined = (o, keyList) ->
      arr = undefined
      item = undefined
      key = undefined
      _i = undefined
      _len = undefined
      arr = []
      _i = 0
      _len = keyList.length

      while _i < _len
        key = keyList[_i]
        item = o[key]
        unless not item
          arr.push ((if item.slug is `undefined` then item else item.slug))
        else
          return arr
        _i++
      arr

    urlFor = (o) ->
      builtUrl = undefined
      klist = undefined
      o.root = "" + NMIS.url_root + "#"  unless o.root?
      o.mode = "summary"  unless o.mode?
      return "" + NMIS.url_root + "#?error"  if not o.lga or not o.state
      klist = ["root", "state", "lga", "mode", "sector", "subsector", "indicator"]
      builtUrl = pushAsDefined(o, klist).join("/")
      builtUrl += "?facility=" + o.facility  unless not o.facility
      builtUrl

    urlFor.extendEnv = (o) ->
      urlFor NMIS.Env.extend(o)

    NMIS.urlFor = urlFor


  NMIS._prepBreadcrumbValues = (e, keys, env) ->
    arr = []
    i = 0
    l = keys.length
    while i < l
      key = keys[i]
      val = e[key]
      if val isnt `undefined`
        name = val.name or val.label or val.slug or val
        env[key] = val
        arr.push [name, NMIS.urlFor(env)]
      else
        return arr
      i++
    arr

  NMIS.Breadcrumb.init "p.bc", levels: []

  Sammy.Application::raise_errors = true

  do ->
    dashboard.get ///#{NMIS.url_root}$///, NMIS.CountryView
    dashboard.get "" + NMIS.url_root + "#/", NMIS.CountryView

  do ->
    # can these 4 lines be a one-liner?
    dashboard.get "" + NMIS.url_root + "#/:state/:lga/facilities/?(#.*)?", NMIS.launch_facilities
    dashboard.get "" + NMIS.url_root + "#/:state/:lga/facilities/:sector/?(#.*)?", NMIS.launch_facilities
    dashboard.get "" + NMIS.url_root + "#/:state/:lga/facilities/:sector/:subsector/?(#.*)?", NMIS.launch_facilities
    dashboard.get "" + NMIS.url_root + "#/:state/:lga/facilities/:sector/:subsector/:indicator/?(#.*)?", NMIS.launch_facilities

  do ->
    # can these 4 lines be a one-liner?
    dashboard.get "" + NMIS.url_root + "#/:state/:lga/summary/?(#.*)?", NMIS.loadSummary
    dashboard.get "" + NMIS.url_root + "#/:state/:lga/summary/:sector/?(#.*)?", NMIS.loadSummary
    dashboard.get "" + NMIS.url_root + "#/:state/:lga/summary/:sector/:subsector/?(#.*)?", NMIS.loadSummary
    dashboard.get "" + NMIS.url_root + "#/:state/:lga/summary/:sector/:subsector/:indicator/?(#.*)?", NMIS.loadSummary

  data_src = "/data/"
  NMIS._data_src_root_url = data_src

  $ ->
    schemaLoad = undefined
    schemaLoad = NMIS.load_schema(data_src)
    schemaLoad.done ->
      dashboard.run()

    schemaLoad.fail ->
      eStyle = undefined
      errorMessage = undefined
      errorMessage = "Failed to load schema file: \"" + data_src + "\".<br>\nPlease correct the data source and refresh."
      eStyle = "margin: 12px 20px 0"
      $("<p>",
        class: "alert-message"
        style: eStyle
      ).html(errorMessage).appendTo "div.display-window-wrap"
      $("<br>").appendTo "div.display-window-wrap"
