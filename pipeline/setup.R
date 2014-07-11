check_r_version <- function(){
    if(R.version$major < 3){
        stop("Your R Version it too low, Upgrade to 3.0.1")
    }else{
        if(R.version$minor < 1.0){
            stop("Your R Version it too low, Upgrade to 3.0.1")
        }
    }   
}
check_r_version()
required_pkgs <- list("dplyr" = "0.2", "lubridate" = "1.3.3", 
                      "RSQLite" = "0.11.4", "RSQLite" = "0.0.1",
                      "plyr" = "1.8.1", "stringr" = "0.6.2",
                      "rjson" = "0.2.13", "foreach" = "1.4.2",
                      "doMC" = "1.3.3", "fpc" = "2.1-7",
                      "sp" = "1.0-15", "devtools" = "1.5")

install_n_load <- function(required_pkgs){
    installed <- installed.packages()[,3]
    to_be_install <- names(required_pkgs)[!names(required_pkgs) %in% 
                                              names(installed)]
    check_update <- required_pkgs[names(required_pkgs) %in% 
                                      names(installed)]
    # install un-installed packages
    sapply(to_be_install, function(pkg){install.packages(pkg)})
    
    # check installed packages and upgrade if version is too low
    sapply(names(check_update), function(pkg){
        pkg <- names(check_update)[1]
        if(check_update[pkg] > installed[names(installed) == pkg]){
            install.packages(pkg)
        }   
    })
}
batch_load <- function(required_pkgs){
    invisible(sapply(names(required_pkgs), 
                     function(pkg){require(pkg, character.only = T)}))
}

install_n_load(required_pkgs)
batch_load(required_pkgs)
rm(install_n_load, batch_load, required_pkgs, check_r_version)

