###
$._template is a shorthand used to combine jquery and underscore-templating to make it quick
and easy-to-build templates.

These two lines are roughly equivalent:
  $._template("#name-template-id", {name:"Alex"}, options)
  _.template($("#name-template-id").html(), {name:"Alex"}, options)

This would expect that you have something like this in the page:
  <script type='text/template' id='name-template-id'>
    <h1>Hello, <%= name %>!</h1>
  </script>

###
_templates = {}
_get_template = (selector)->
  q = $(selector)
  throw new Error("Attention: '#{selector}' template does not exist.") if q.length == 0
  q.html()

_template = (selector, data={}, options={})->
  _templates[selector] ||= _get_template(selector)
  _.template(_templates[selector], data, options)

$._template = _template

###
The $._template.require function allows you to write code that depends on
a given template being loaded into the page.

Its use is optional.
It would be convenient for preparing for edge cases.
###
required_templates        = []
dom_is_ready              = false
needs_check_for_required  = false

_template.require = (templates)->
  needs_check_for_required = true
  templates = [templates] unless templates instanceof Array
  for tname in templates
    required_templates.push(tname) unless tname in required_templates
  check_for_required() if dom_is_ready

check_for_required = ()->
  missing_templates = []
  for tid in required_templates
    missing_templates.push tid if $(tid).length == 0
  throw new Error("Attention: #{missing_templates.length} missing template(s): '#{missing_templates.join(', ')}'") if $(tid).length == 0

$ ->
  dom_is_ready = true
  _.defer(check_for_required) if needs_check_for_required
