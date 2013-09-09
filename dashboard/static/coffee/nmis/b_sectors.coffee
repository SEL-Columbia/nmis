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
