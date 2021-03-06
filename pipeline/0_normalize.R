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
                                               "private_profit" = "private")),
            zone = revalue(zone, c("north_central" = "North-Central",
                                    "north_east" = "Northeast",
                                    "north_west" = "Northwest",
                                    "south_east" = "Southeast",
                                    "south_south" = "South-South",
                                    "south_west" = "Southwest")),
            latitude = get_lat(gps),
            longitude = get_lon(gps),
            facility_name = xxx_replace(facility_name),
            ward = xxx_replace(ward),
            community = xxx_replace(community)
            
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
                                     "osunNA" = "osun_irepodun", ## SADLY: two possible values for osun
                                     "oyoNA" = "oyo_surulere",
                                     "plateauNA" = "plateau_bassa"))
            )
        d <- rbind_list(filter(d, lga != "NA"), messed_up_lgas)
    }

    
    return(d %.% ## drop _dontknow and _calc values, which are only meant for monitoring
        dplyr::select(-matches('_dontknow', '_calc'),
                      formhub_photo_id = photo_facility,
                      unique_lga = lga,
                      survey_id = uuid,
                      facility_id = facility_ID,
                      matches('.')) %.%
        dplyr::mutate(facility_id = sector_prefix(facility_id, sector)) %.%
        dplyr::filter(!(is.na(latitude) & is.na(longitude)))
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
                                      "dentalclinic" = "none", # these are being dropped
                                      "federalmedicalcentre" = "specialist_hospital",
                                      "generalhospital" = "general_hospital",
                                      "healthpostdispensary" = "health_post",
                                      "maternity" = "primary_health_centre",
                                      "None" = "none", "other" = "none", # these are being dropped
                                      "primaryhealthcarecentre" = "primary_health_centre",
                                      "primaryhealthclinic" = "basic_health_centre",
                                      "private" = "none", # also dropping private facilities -- there are only 24
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
        return(d %.% 
                   dplyr::mutate(facility_id = NA,
                                 latitude = get_lat(gps),
                                 longitude = get_lon(gps),
                                 facility_name = xxx_replace(facility_name),
                                 ward = xxx_replace(ward),
                                 community = xxx_replace(community)) %.%
                   dplyr::select(survey_id = uuid, matches('.')) %.%
                   dplyr::filter(!(is.na(latitude) & is.na(longitude))))
    } else {
        stop("Sector and Survey Name normalization not yet supported.")
    }
}


normalize_external = function(d) {
           return(d %.% mutate(prevalence_of_underweight_children_u5 = pct_convtr(prevalence_of_underweight_children_u5),
                               prevalence_of_stunting_children_u5 = pct_convtr(prevalence_of_stunting_children_u5),
                               prevalence_of_wasting_children_u5 = pct_convtr(prevalence_of_wasting_children_u5),
                               proportion_of_children_u5_diarrhea_treated_with_ors_med = pct_convtr(proportion_of_children_u5_diarrhea_treated_with_ors_med),
                               prevalence_of_hiv = pct_convtr(prevalence_of_hiv),
                               percentage_of_individuals_tested_for_hiv_ever = pct_convtr(percentage_of_individuals_tested_for_hiv_ever),
                               proportion_children_u5_sleeping_under_itns_or_IRS_dwellings = pct_convtr(proportion_children_u5_sleeping_under_itns_or_IRS_dwellings),
                               percent_receiving_antenatal_care = pct_convtr(percent_receiving_antenatal_care),
                               percentage_pregnant_women_tested_for_hiv_during_pregnancy = pct_convtr(percentage_pregnant_women_tested_for_hiv_during_pregnancy),
                               percentage_households_with_access_to_improved_water_sources = pct_convtr(percentage_households_with_access_to_improved_water_sources),
                               percentage_households_with_access_to_improved_sanitation = pct_convtr(percentage_households_with_access_to_improved_sanitation),
                               immunization_rate_basic = pct_convtr(immunization_rate_basic),
                               proportion_of_births_by_skilled_health_personnel = pct_convtr(proportion_of_births_by_skilled_health_personnel),
                               immunization_rate_measles = pct_convtr(immunization_rate_measles))
           )
}
