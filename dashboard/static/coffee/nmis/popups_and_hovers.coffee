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

