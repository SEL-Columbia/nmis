require(formhub); require(plyr); require(dplyr); 

## Normalize mopup surveys. We use "survey_name" to see what the name of the survey was,
## and map question names and values as required. Unmatching and rarely used columns are just dropped.
normalize_mopup = function(formhubData, survey_name, sector) {
    d <- tbl_df(as.data.frame(formhubData)) %.% mutate(
        ## Create facility_type_display using the formhub form
        facility_type_display = replaceColumnNamesWithLabels(formhubData, 'facility_type'))
    
    ## Survey_name: mopup, mopup_new, or mopup_pilot
    # mopup and mopup_new are pretty much the same, except mopup has some LGAs mistakenly as NA
    if(survey_name %in% c("mopup", "mopup_new")) {
        d <- d %.% dplyr::select(-facility_list_yn, -grid_proximity_if_not_connected,
                                 formhub_photo_id = photo_facility, matches('.'))
    } else if (survey_name %in% c("mopup_pilot")) {
        d <- d %.% dplyr::select(-new_old,
                                 formhub_photo_id = photo_facility, matches('.'))
    } else {
        stop("survey_name or sector is invalid")
    }
    
    ## These are all useful at early monitoring stages. Drop for the future.
    d %.% dplyr::select(-matches('_dontknow')) %.%
        dplyr::mutate(
            phcn_electricity = phcn_electricity == 'yes'
    )
}

normalize_661 = function(d, survey_name, sector) {
    ## Survey_name: mopup, mopup_new, or mopup_pilot
    # mopup and mopup_new are pretty much the same, except mopup has some LGAs mistakenly as NA
    stopifnot(survey_name %in% c("661") & sector %in% c("education", "health"))
    if (survey_name %in% c("661")) {
        d %.% mutate(
                facility_ID = NA
            )
    } else {
        stop("Sector and Survey Name normalization not yet supported.")
    }
}