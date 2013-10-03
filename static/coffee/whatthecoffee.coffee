  class Sector
    constructor: (d)->
      # "extend" d onto this object but prepend underscore to certain keys
      changed_keys = "subgroups columns default".split ' '
      @[if k in changed_keys then "_#{k}" else k] = val  for k, val of d

 -------------------------------------------------------


 