#
#Hopefully we can get rid of this file and put most of this functionality back
#into the nmis_ui project, but for the moment that shouldn't prevent us from
#making quick changes.
#

#
#  
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

data_src = undefined
overviewObj = undefined
wElems = undefined
NMIS.settings =
  openLayersRoot: "/static/openlayers/"
  pathToMapIcons: "/static/images"

NMIS.url_root = (->
  url_root = undefined
  url_root = "" + window.location.pathname
  url_root = url_root.replace("index.html", "")  unless not ~url_root.indexOf("index.html")
  url_root
)()
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
(->
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
)()
NMIS._prepBreadcrumbValues = (e, keys, env) ->
  arr = undefined
  i = undefined
  key = undefined
  l = undefined
  name = undefined
  val = undefined
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

NMIS.Breadcrumb.init "p.bc",
  levels: []

Sammy.Application::raise_errors = true
(->
  dashboard.get new RegExp(NMIS.url_root + "$"), NMIS.CountryView
  dashboard.get "" + NMIS.url_root + "#/", NMIS.CountryView
)()
(->
  dashboard.get "" + NMIS.url_root + "#/:state/:lga/facilities/?(#.*)?", NMIS.launch_facilities
  dashboard.get "" + NMIS.url_root + "#/:state/:lga/facilities/:sector/?(#.*)?", NMIS.launch_facilities
  dashboard.get "" + NMIS.url_root + "#/:state/:lga/facilities/:sector/:subsector/?(#.*)?", NMIS.launch_facilities
  dashboard.get "" + NMIS.url_root + "#/:state/:lga/facilities/:sector/:subsector/:indicator/?(#.*)?", NMIS.launch_facilities
)()
(->
  dashboard.get "" + NMIS.url_root + "#/:state/:lga/summary/?(#.*)?", NMIS.loadSummary
  dashboard.get "" + NMIS.url_root + "#/:state/:lga/summary/:sector/?(#.*)?", NMIS.loadSummary
  dashboard.get "" + NMIS.url_root + "#/:state/:lga/summary/:sector/:subsector/?(#.*)?", NMIS.loadSummary
  dashboard.get "" + NMIS.url_root + "#/:state/:lga/summary/:sector/:subsector/:indicator/?(#.*)?", NMIS.loadSummary
)()
(->
  hash = undefined
  href = undefined
  newUrl = undefined
  srchStr = undefined
  ss = undefined
  ssData = undefined
  _ref = undefined
  srchStr = "" + window.location.search
  if -1 isnt srchStr.indexOf("data=")
    href = "" + window.location.href
    hash = "" + window.location.hash
    _ref = srchStr.match(/data=(.*)$/)
    ss = _ref[0]
    ssData = _ref[1]

    $.cookie "data-source", ssData  if ssData
    newUrl = href.split("?")[0]
    newUrl += hash  if hash
    window.location.href = newUrl
)()
data_src = "/static/protected_data/"
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
