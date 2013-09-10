/*
Hopefully we can get rid of this file and put most of this functionality back
into the nmis_ui project, but for the moment that shouldn't prevent us from
making quick changes.
*/

(function() {
  var data_src, overviewObj, wElems;

  NMIS.settings = {
     openLayersRoot: "/static/openlayers/",
     pathToMapIcons: "/static/images"
  };

  NMIS.url_root = (function() {
    var url_root;
    url_root = "" + window.location.pathname;
    if (!!~url_root.indexOf("index.html")) {
      url_root = url_root.replace("index.html", "");
    }
    return url_root;
  })();

  /*
  
  initializing a Sammy.js object, called "dashboard".
  This will route URLs and handle links to pre-routed URLs.
  
  routes are defined in nmis_facilities.js and nmis_summary.js by:
     dashboard.get("/url/:variable", callback);
  
  URL actions can be triggered by calling:
     dashboard.setLocation("/url/hello");
  */


  this.dashboard = $.sammy("body", function() {
    return this.get("" + NMIS.url_root + "#/:state/:lga/?", function() {
      var redirect,
        _this = this;
      redirect = function() {
        return dashboard.setLocation("" + NMIS.url_root + "#/" + _this.params.state + "/" + _this.params.lga + "/summary");
      };
      return _.delay(redirect, 500);
    });
  });

  NMIS.DisplayWindow.init(".content", {
    offsetElems: ".topbar .fill .container",
    sizeCookie: true
  });

  overviewObj = {
    name: "Overview",
    slug: "overview"
  };

  NMIS.init();

  wElems = NMIS.DisplayWindow.getElems();

  NMIS._wElems = wElems;

  NMIS.LocalNav.init(wElems.wrap, {
    sections: [[["mode:summary", "LGA Summary", "#"], ["mode:facilities", "Facility Detail", "#"]], [["sector:overview", "Overview", "#"], ["sector:health", "Health", "#"], ["sector:education", "Education", "#"], ["sector:water", "Water", "#"]]]
  });

  NMIS.LocalNav.hide();

  (function() {
    var pushAsDefined, urlFor;
    pushAsDefined = function(o, keyList) {
      var arr, item, key, _i, _len;
      arr = [];
      for (_i = 0, _len = keyList.length; _i < _len; _i++) {
        key = keyList[_i];
        item = o[key];
        if (!!item) {
          arr.push((item.slug === undefined ? item : item.slug));
        } else {
          return arr;
        }
      }
      return arr;
    };
    urlFor = function(o) {
      var builtUrl, klist;
      if (o.root == null) {
        o.root = "" + NMIS.url_root + "#";
      }
      if (o.mode == null) {
        o.mode = "summary";
      }
      if (!o.lga || !o.state) {
        return "" + NMIS.url_root + "#?error";
      }
      klist = ["root", "state", "lga", "mode", "sector", "subsector", "indicator"];
      builtUrl = pushAsDefined(o, klist).join("/");
      if (!!o.facility) {
        builtUrl += "?facility=" + o.facility;
      }
      return builtUrl;
    };
    urlFor.extendEnv = function(o) {
      return urlFor(NMIS.Env.extend(o));
    };
    return NMIS.urlFor = urlFor;
  })();

  NMIS._prepBreadcrumbValues = function(e, keys, env) {
    var arr, i, key, l, name, val;
    arr = [];
    i = 0;
    l = keys.length;
    while (i < l) {
      key = keys[i];
      val = e[key];
      if (val !== undefined) {
        name = val.name || val.label || val.slug || val;
        env[key] = val;
        arr.push([name, NMIS.urlFor(env)]);
      } else {
        return arr;
      }
      i++;
    }
    return arr;
  };

  NMIS.Breadcrumb.init("p.bc", {
    levels: []
  });

  Sammy.Application.prototype.raise_errors = true;

  (function() {
    dashboard.get(new RegExp(NMIS.url_root + "$"), NMIS.CountryView);
    return dashboard.get("" + NMIS.url_root + "#/", NMIS.CountryView);
  })();


  (function() {
    dashboard.get("" + NMIS.url_root + "#/:state/:lga/facilities/?(#.*)?", NMIS.launch_facilities);
    dashboard.get("" + NMIS.url_root + "#/:state/:lga/facilities/:sector/?(#.*)?", NMIS.launch_facilities);
    dashboard.get("" + NMIS.url_root + "#/:state/:lga/facilities/:sector/:subsector/?(#.*)?", NMIS.launch_facilities);
    return dashboard.get("" + NMIS.url_root + "#/:state/:lga/facilities/:sector/:subsector/:indicator/?(#.*)?", NMIS.launch_facilities);
  })();

  (function() {
    dashboard.get("" + NMIS.url_root + "#/:state/:lga/summary/?(#.*)?", NMIS.loadSummary);
    dashboard.get("" + NMIS.url_root + "#/:state/:lga/summary/:sector/?(#.*)?", NMIS.loadSummary);
    dashboard.get("" + NMIS.url_root + "#/:state/:lga/summary/:sector/:subsector/?(#.*)?", NMIS.loadSummary);
    return dashboard.get("" + NMIS.url_root + "#/:state/:lga/summary/:sector/:subsector/:indicator/?(#.*)?", NMIS.loadSummary);
  })();


  (function() {
    /*
      If the url has a search string that includes "?data=xyz", then this
      will assign the data-source cookie to the value and then redirect to
      the URL without the data-source in it.
    */

    var hash, href, newUrl, srchStr, ss, ssData, _ref;
    srchStr = "" + window.location.search;
    if (-1 !== srchStr.indexOf("data=")) {
      href = "" + window.location.href;
      hash = "" + window.location.hash;
      _ref = srchStr.match(/data=(.*)$/), ss = _ref[0], ssData = _ref[1];
      if (ssData) {
        $.cookie("data-source", ssData);
      }
      newUrl = href.split("?")[0];
      if (hash) {
        newUrl += hash;
      }
      return window.location.href = newUrl;
    }
  })();

  data_src = "/data/"

  NMIS._data_src_root_url = data_src;

  $(function() {
    var schemaLoad;
    schemaLoad = NMIS.load_schema(data_src);
    schemaLoad.done(function() {
      return dashboard.run();
    });
    return schemaLoad.fail(function() {
      var eStyle, errorMessage;
      errorMessage = "Failed to load schema file: \"" + data_src + "\".<br>\nPlease correct the data source and refresh.";
      eStyle = "margin: 12px 20px 0";
      $('<p>', {
        "class": 'alert-message',
        style: eStyle
      }).html(errorMessage).appendTo('div.display-window-wrap');
      return $('<br>').appendTo('div.display-window-wrap');
    });
  });

}).call(this);
