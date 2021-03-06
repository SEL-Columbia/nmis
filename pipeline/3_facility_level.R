require(dplyr); require(stringr); require(lubridate)


## Transformations for all facilities, mopup data, for facility level
all_mopup_facility_level = function(facility_data) {
    return(facility_data %.% 
        dplyr::select(
            # RENAMING FIELDS to be nicer; syntax is: new_col_name = old_col_name
            submission_time = X_submission_time, #TODO: use submission_time 
            latitude = X_gps_latitude,
            longitude = X_gps_longitude,
            matches('.') # this means match everything; ensure that we don't drop any columns
        ) %.% 
        dplyr::mutate(
            src = "mopup",
            # INFRASTRUCTURE
            date_of_survey = as.character(as.Date(iso8601DateTimeConvert(submission_time))), #TODO: fix
            improved_water_supply = improved_water_supply.tap | improved_water_supply.protected_well |
                improved_water_supply.rainwater | improved_water_supply.handpump,
            improved_sanitation = improved_sanitation.vip_latrine | 
                improved_sanitation.pit_latrine_with_slab | improved_sanitation.flush,
            improved_functional_water = improved_water_supply & improved_water_functionality == 'functional',
            # NEEDED for aggregations
            access_to_alternative_power_source = power_sources.generator | power_sources.solar_system,
            # USEFUL DATA POINTS for DATA output, not in NMIS
            power_access = power_sources.generator | power_sources.solar_system | power_sources.grid
        )
    )
}
## Transformations for education facilities, mopup data, for facility level
education_mopup_facility_level = function(education_data) {
    return(all_mopup_facility_level(education_data) %.% 
        dplyr::mutate(
            sector = "education",
            ## The following are used in other parts of the pipeline
            ratio_students_to_toilet = num_students_total / num_toilets_total,
            pupil_class_ratio = num_students_total / num_classrms_total,
            natl_curriculum_yn = education_type %in% c('formal_only', 'integrated'),
            
            ## INFRASTRUCTURE
            ## note: these are also written like this for historical consistency
            chalkboard_each_classroom_yn = num_classrm_w_chalkboard == num_classrms_total
        ) %.%
        dplyr::select( ## RENAME: new_col_name = old_name
            num_tchr_full_time = num_tchrs_total,
            matches('.') # this means match everything; ensure that we don't drop any columns
        )
    )
}
## Transformations for health facilities, mopup data, for facility level
health_mopup_facility_level = function(health_data) {
    return(all_mopup_facility_level(health_data) %.% 
        dplyr::select(
            # FIELDS THAT NEED RENAMING
            num_nursemidwives_fulltime = num_midwives_fulltime,
            maternal_health_delivery_services = delivery_services,
            child_health_measles_immun_calc = measles_yn,
            matches('.') # this means match everything; ensure that we don't drop any columns
        ) %.% 
        dplyr::mutate(
            sector = "health",
            # NEWLY CALCULATED FIELDS
            skilled_birth_attendant = ((num_nursemidwives_fulltime > 0) | (num_doctors_fulltime > 0))  
        )
    )
}
