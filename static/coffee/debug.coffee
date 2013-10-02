# debug code comes from paul irish's html5 boilerplate
# https://github.com/h5bp/html5-boilerplate/blob/master/js/plugins.js
unless window.console? and console.log?
  (->
    noop = ->

    methods = ["assert", "clear", "count", "debug", "dir", "dirxml", "error", "exception", "group", "groupCollapsed", "groupEnd", "info", "log", "markTimeline", "profile", "profileEnd", "markTimeline", "table", "time", "timeEnd", "timeStamp", "trace", "warn"]
    length = methods.length
    console = window.console = {}
    console[methods[length]] = noop  while length--
  )()

# usage: log('inside coolFunc',this,arguments);
# http://paulirish.com/2009/log-a-lightweight-wrapper-for-consolelog/
@log = ->
  log.history = log.history or [] # store logs to an array for reference
  log.history.push arguments
  console.log.apply console, Array::slice.call(arguments) if window.console

@log.error = ->
  console.error.apply console, Array::slice.call(arguments) if window.console

