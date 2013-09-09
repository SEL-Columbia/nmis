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
