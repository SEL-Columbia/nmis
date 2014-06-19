require(formhub); require(plyr); require(dplyr); 

## Normalize mopup surveys. We use "survey_name" to see what the name of the survey was,
## and map question names and values as required. Unmatching and rarely used columns are just dropped.
normalize_mopup = function(formhubData, survey_name, sector) {
    d <- formhubData %.%
        formhub::remapAllColumns(remap=c("yes"=TRUE, "no"=FALSE, "dk"=NA)) %.%
        dplyr::tbl_df() %.%
        dplyr::mutate(
            ## Create facility_type_display using the formhub form
            facility_type_display = replaceColumnNamesWithLabels(formhubData, 'facility_type'),
            management = revalue(management, c("federal_gov" = "public",
                                               "local_gov" = "public",
                                               "state_gov" = "public",
                                               "private_non_profit" = "private",
                                               "private_profit" = "private"))
        )
    ## Survey_name: mopup, mopup_new, or mopup_pilot
    # mopup and mopup_new are pretty much the same, except mopup has some LGAs mistakenly as NA
    if(survey_name %in% c("mopup", "mopup_new")) {
        d <- d %.%
            dplyr::select(-facility_list_yn, -grid_proximity_if_not_connected, matches('.'))
    } else if (survey_name %in% c("mopup_pilot")) {
        d <- d %.% 
            dplyr::select(-new_old, matches('.'))
    } else {
        stop("survey_name or sector is invalid")
    }
    #### CORRECT THE MISTAKE WHERE SOME LGAs were given the unique_lga value "NA" by mistake
    if(survey_name == "mopup") {
        messed_up_lgas <- d %.% 
            dplyr::filter(lga=="NA") %.%
            dplyr::mutate(
                lga = str_c(state, lga),   # add state names to make revaluing possible
                lga = revalue(lga, c("adamawaNA" = "adamawa_larmurde",
                                     "nasarawaNA" = "nasarawa_obi",
                                     "osunNA" = "NA", ## SADLY: two possible values for osun
                                     "oyoNA" = "oyo_surulere",
                                     "plateauNA" = "plateau_bassa"))
            )
        d <- rbind_list(filter(d, lga != "NA"), messed_up_lgas)
    }
    
    return(d %.% ## drop _dontknow and _calc values, which are only meant for monitoring
        dplyr::select(-matches('_dontknow', '_calc'),
                      formhub_photo_id = photo_facility,
                      unique_lga = lga,
                      matches('.')) # 
    )
}

normalize_2012 = function(d, survey_name, sector) {
    ## Survey_name: mopup, mopup_new, or mopup_pilot
    # mopup and mopup_new are pretty much the same, except mopup has some LGAs mistakenly as NA
    stopifnot(survey_name %in% c("2012") & sector %in% c("education", "health", "water"))
    if (survey_name %in% c("2012")) {
        if(sector == 'health') {
            d <- d %.% 
                dplyr::mutate(
                    facility_type = revalue(facility_type,
                                    c("comprehensivehealthcentre" = "district_hospital",
                                      "cottagehospital" = "general_hospital",
                                      "dentalclinic" = "DROP", # these are being dropped
                                      "federalmedicalcentre" = "specialist_hospital",
                                      "generalhospital" = "general_hospital",
                                      "healthpostdispensary" = "health_post",
                                      "maternity" = "primary_health_centre",
                                      "None" = "DROP", "other" = "DROP", # these are being dropped
                                      "primaryhealthcarecentre" = "primary_health_centre",
                                      "primaryhealthclinic" = "basic_health_centre",
                                      "private" = "DROP", # also dropping private facilities -- there are only 24
                                      "specialisthospital" = "specialist_hospital",
                                      "teachinghospital" = "teaching_hospital",
                                      "wardmodelphccentre" = "primary_health_centre"))
                ) %.% 
                dplyr::select( # the following are renames. format: new_value = old_value
                    ## RENAMING SOME BASELINE INDICATORS TO MATCH WITH NEW NAMES
                    malaria_treatment_artemisinin = medication_anti_malarials,
                    matches('.') # this is necessary, in order not to drop the rest of the columns
                )
        } else if (sector == "education") {
            d <- d %.% 
                dplyr::mutate(
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
                ) %.% 
                dplyr::select( # the following are renames. format: new_value = old_value
                    ## RENAMING SOME BASELINE INDICATORS TO MATCH WITH NEW NAMES
                    num_classrms_repair = num_classrms_need_maj_repairs,
                    matches('.') # this is necessary, in order not to drop the rest of the columns
                )
        }
        return(mutate(d, facility_ID = NA))
    } else {
        stop("Sector and Survey Name normalization not yet supported.")
    }
}
