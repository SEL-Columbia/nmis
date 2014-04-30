PATHS = RJSONIO::fromJSON("CONFIG.JSON")

l_ply(PATHS, function(path) {
    if(!file.exists(path)) 
       stop("CONFIG.JSON contains non-existent file path:", path)
})
