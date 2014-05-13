require(formhub); require(plyr); require(dplyr); 

## Normalize mopup surveys. We use "survey_name" to see what the name of the survey was,
## and map question names and values as required. Unmatching and rarely used columns are just dropped.
normalize_mopup = function(formhubData, survey_name, sector) {
    d <- tbl_df(remapAllColumns(formhubData, remap=c("yes"=TRUE, "no"=FALSE, "dk"=NA))) %.%
        mutate(
            ## Create facility_type_display using the formhub form
            facility_type_display = replaceColumnNamesWithLabels(formhubData, 'facility_type')
        )
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
    d %.% dplyr::select(-matches('_dontknow', '_calc'))
}

normalize_2012 = function(d, survey_name, sector) {
    ## Survey_name: mopup, mopup_new, or mopup_pilot
    # mopup and mopup_new are pretty much the same, except mopup has some LGAs mistakenly as NA
    stopifnot(survey_name %in% c("2012") & sector %in% c("education", "health"))
    if (survey_name %in% c("2012")) {
        if(sector == 'health') {
            d <- d %.% 
                mutate(
                    facility_type = revalue(facility_type,
                                    c("comprehensivehealthcentre" = "district_hospital",
                                      "cottagehospital" = "general_hospital",
                                      "dentalclinic" = "none", # these are being dropped
                                      "federalmedicalcentre" = "specialist_hospital",
                                      "generalhospital" = "general_hospital",
                                      "healthpostdispensary" = "health_post",
                                      "maternity" = "primary_health_centre",
                                      "None" = "none", "other" = "none",
                                      "primaryhealthcarecentre" = "primary_health_centre",
                                      "primaryhealthclinic" = "basic_health_centre",
                                      "private" = "none", # also dropping private facilities -- there are only 24
                                      "specialisthospital" = "specialist_hospital",
                                      "teachinghospital" = "teaching_hospital",
                                      "wardmodelphccentre" = "primary_health_centre"))
                ) %.% select( # the following are renames. format: new_value = old_value
                    ## RENAMING SOME BASELINE INDICATORS TO MATCH WITH NEW NAMES
                    malaria_treatment_artemisinin = medication_anti_malarials,
                    matches('.') # this is necessary, in order not to drop the rest of the columns
                )
        } else if (sector == "education") {
            d <- d %.% 
                mutate(
                    facility_type = revalue(facility_type,
                                            c("adult_ed" = "DROP",
                                              "adult_lit" = "DROP",
                                              "adult_vocational" = "DROP",
                                              "js" = "junior_sec_only",
                                              "js_ss" = "junior_and_senior_sec",
                                              "preprimary" = "DROP",
                                              "preprimary_only" = "DROP",
                                              "preprimary_primary" = "preprimary_and_primary",
                                              "primary" = "primary_only",
                                              "primary_js" = "primary_and_junior_sec",
                                              "primary_js_ss" = "primary_junior_and_senior_sec",
                                              "science_technical" = "DROP",
                                              "senior_sec_only" = "DROP",
                                              "ss" = "DROP",
                                              "vocational" = "DROP",
                                              "vocational_post_primary" = "DROP",
                                              "vocational_post_secondary" = "DROP"))
                )
        }
        return(d %.% mutate(facility_ID = NA))
    } else {
        stop("Sector and Survey Name normalization not yet supported.")
    }
}