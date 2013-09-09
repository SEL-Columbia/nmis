###
This file is meant to initialize the NMIS object which includes
independently testable modules.
###
@NMIS = {} unless @NMIS?
unless @NMIS.settings
  @NMIS.settings =
    openLayersRoot: "./openlayers/"
    pathToMapIcons: "./images"

NMIS.expected_modules = ["Tabulation","clear","Sectors","validateData","data","FacilityPopup","Breadcrumb","IconSwitcher","MapMgr","FacilityHover"]

_.templateSettings =
  escape: /<{-([\s\S]+?)}>/g
  evaluate: /<{([\s\S]+?)}>/g
  interpolate: /<{=([\s\S]+?)}>/g

do ->
  ###
  This is the abdomen of the NMIS code. NMIS.init() initializes "data" and "opts"
  which were used a lot in the early versions.

  Many modules still access [facility-]data through NMIS.data()

  opts has more-or-less been replaced by NMIS.Env()
  ###
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
          _.each @items, (item) ->
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
  NMIS.dataObjForSector = (sectorSlug) ->
    sector = NMIS.Sectors.pluck(sectorSlug)
    o = {}
    _(data).each (datum, id) ->
      o[id] = datum  if datum.sector.slug is sector.slug
    o

  #uses: data
  NMIS.data = -> data

do ->
  ###
  the internal "value" function takes a value and returns a 1-2 item list:
  The second returned item (when present) is a class name that should be added
  to the display element.

    examples:
  
    value(null)
    //  ["--", "val-null"]
  
    value(0)
    //  ["0"]
  
    value(true)
    //  ["Yes"]
  ###
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

  ###
  The main function, "NMIS.DisplayValue" receives an element
  and displays the appropriate value.
  ###
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
