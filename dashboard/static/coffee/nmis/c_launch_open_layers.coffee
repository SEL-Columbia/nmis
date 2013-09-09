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

NMIS.launchOpenLayers = do ->
  launchDfd = $.Deferred()

  scriptsStarted = false
  scriptsFinished = false
  mapElem = undefined
  opts = undefined
  context = {}
  loadingMessageElement = false
  defaultOpts =
    elem: "#map"
    centroid:
      lat: 0.000068698255561324
      lng: 0.000083908685869343

    olImgPath: "/static/openlayers/default/img/"
    tileUrl: "http://b.tiles.mapbox.com/modilabs/"
    layers: [["Nigeria", "nigeria_base"]]
    overlays: []
    defaultLayer: "google"
    layerSwitcher: true
    loadingElem: false
    loadingMessage: "Please be patient while this map loads..."
    zoom: 6
    maxExtent: [-20037500, -20037500, 20037500, 20037500]
    restrictedExtent: [-4783.9396188051, 463514.13943762, 1707405.4936624, 1625356.9691642]

  scriptsAreLoaded = ->
    ifDefined = (str) ->
      if str is "" or str is `undefined`
        `undefined`
      else
        str
    loadingMessageElement.hide()  unless not loadingMessageElement
    OpenLayers.IMAGE_RELOAD_ATTEMPTS = 3
    OpenLayers.ImgPath = opts.olImgPath
    ob = opts.maxExtent
    re = opts.restrictedExtent
    options =
      projection: new OpenLayers.Projection("EPSG:900913")
      displayProjection: new OpenLayers.Projection("EPSG:4326")
      units: "m"
      maxResolution: 156543.0339
      restrictedExtent: new OpenLayers.Bounds(re[0], re[1], re[2], re[3])
      maxExtent: new OpenLayers.Bounds(ob[0], ob[1], ob[2], ob[3])

    mapId = mapElem.get(0).id
    mapserver = opts.tileUrl
    mapLayerArray = []
    context.mapLayers = {}
    $.each opts.overlays, (k, ldata) ->
      ml = new OpenLayers.Layer.TMS(ldata[0], [mapserver],
        layername: ldata[1]
        type: "png"
        transparent: "true"
        isBaseLayer: false
      )
      mapLayerArray.push ml
      context.mapLayers[ldata[1]] = ml

    $.each opts.layers, (k, ldata) ->
      ml = new OpenLayers.Layer.TMS(ldata[0], [mapserver],
        layername: ldata[1]
        type: "png"
      )
      mapLayerArray.push ml
      context.mapLayers[ldata[1]] = ml

    context.waxLayerDict = {}
    context.activeWax
    mapId = mapElem.get(0).id = "-openlayers-map-elem"  unless mapId
    context.map = new OpenLayers.Map(mapId, options)
    window.__map = context.map
    googleSat = new OpenLayers.Layer.Google("Google",
      type: "satellite"
    )
    googleMap = new OpenLayers.Layer.Google("Roads",
      type: "roadmap"
    )
    mapLayerArray.push googleSat, googleMap
    context.map.addLayers mapLayerArray
    context.map.setBaseLayer googleSat  if opts.defaultLayer is "google"
    context.map.addControl new OpenLayers.Control.LayerSwitcher()  if opts.layerSwitcher
    scriptsFinished = true

  # the launch function is returned
  launch = (_opts) ->
    opts = $.extend({}, defaultOpts, _opts)  if opts is `undefined`
    mapElem = $(opts.elem)  if mapElem is `undefined`
    loadingMessageElement = $(opts.loadingElem).text(opts.loadingMessage).show()  if !!opts.loadingElem and !!opts.loadingMessage
    unless scriptsStarted
      scriptsStarted = true
      gmLoad = NMIS.loadGoogleMaps()
      gmLoad.done (gmaps)->
        olLoad = NMIS.loadOpenLayers()
        olLoad.done (ol)->
          scriptsAreLoaded()
          launchDfd.resolve()

        olLoad.fail (o, err, message)->
          launchDfd.reject o, err, message

      gmLoad.fail (o, err, message)->
        launchDfd.reject o, err, message

    launchDfd.promise()
