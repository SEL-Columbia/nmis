$.when_O = (arg_O)->
  ###
  When handling multiple $.Defferreds,

  $.when(...) receives a list and then passes
  a list of arguments.

  This mini plugin receives an object of named deferreds
  and resolves with an object with the results.

  Example:

  var shows = {
    "simpsons": $.getJSON(simpsons_shows),
    "southPark": $.getJSON(southpark_shows)
  };

  $.when_O(shows).done(function(showResults){
    var showNames = [];
    if(showResults.familyGuy) showNames.push("Family Guy")
    if(showResults.simpsons) showNames.push("Simpsons")
    if(showResults.southPark) showNames.push("South Park")

    console.log(showNames);
    //  ["Simpsons", "South Park"]
  });

  ###

  defferred = new $.Deferred

  promises = []
  finished = {}

  for key, val of arg_O
    promises.push val
    finished[key] = false

  $.when.apply(null, promises).done ()->
    results = {}
    for key, val of arg_O
      ###
      in $.getJSON, for example, I want to access the parsedJSON object so
      I don't want to finish everything until all success callback have been
      called.
      ###
      do ->
        local_key = key
        val.done (result)->
          finished[local_key] = true
          results[local_key] = result

          ###
          Continue iff all are finished.
          ###
          completed = true
          completed = false for k, fin of finished when !fin
          defferred.resolve results if completed

  defferred