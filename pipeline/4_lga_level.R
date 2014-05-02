require(dplyr); require(stringr); require(lubridate)
source("nmis_functions.R")

## Education Facilities LGA-level indicators for mopup
## The way this works, roughly is:
## (1) Create additional facility-level indicators that are helpful in our later calculations
## (2) Define a function which will calculate indicators given a "level". Level is primary or junior.
##     We do this so we don't have to repeat the same code for primary and junior secondary indicators.
##     Note that before returning, based on level, this function tacks on _primary or _js to the indicator name.
## (3) Actually call the function on both primary and js levels, and save the values.
## (4) Make overall indicators (ie, ones that are not specific to each level).
## (5) Join everything together
## (6) Rename some of our indicators to possibly non-standard form. (Should go away).
education_mopup_lga_indicators = function(education_data) {
    ## (1) Create additional facility-level indicators that are helpful in our later calculations
    education_data = education_data %.% mutate(
        is_public = management %in% c('federal_gov', 'local_gov', 'state_gov'),
        natl_curriculum_yn = education_type %in% c('formal_only', 'integrated')
    )
    ## (2) Define a function which will calculate indicators given a "level". Level is primary or junior.
    ## primary and junior secondary indicator transformations. Note: columns will end with _primary or _js
    primary_and_junior_sec_indicators = function(data, level) {
        stopifnot(level %in% c("primary", "junior")) # make sure level is either Primary or Junior
        data <- data %.% 
            group_by(lga) %.% 
            filter(str_detect(facility_type, level)) %.%
            dplyr::summarize(
                num_schools = n(),
                percent_management_public = mean(is_public, na.rm=T),
                percent_natl_curriculum = mean(natl_curriculum_yn, na.rm=T),
                avg_num_tchrs = mean(num_tchr_full_time, na.rm=T),
                avg_num_students = mean(num_students_total, na.rm=T),
                avg_num_classrms = mean(num_classrms_total, na.rm=T),
                avg_num_toilets = mean(num_toilets_total, na.rm=T),
                percent_functional_water = mean(functional_water, na.rm=T),
                proportion_schools_chalkboard_all_rooms = mean(chalkboard_each_classroom_yn, na.rm=T),
                percent_improved_sanitation = mean(improved_sanitation, na.rm=T),
                percent_phcn_electricity = mean(phcn_electricity, na.rm=T),
                ## The following are "ratio" indicators
                pupil_toilet_ratio = ratio(num_students_total, num_toilets_total),
                student_classroom_ratio_lga = ratio(num_students_total, num_classrms_total),
                proportion_teachers_nce = ratio(num_tchrs_with_nce, num_tchr_full_time),
                pupil_teachers_ratio_lga = ratio(num_students_total, num_tchr_full_time)
            )
        ## Rename our indicators to end with _primary and _js. Note: don't rename lga, which is the first column.
        level_suffix = c('primary' = 'primary', 'junior' = 'js')[level]
        names(data)[-1] <- paste(names(data)[-1], level_suffix, sep="_")
        return(data)
    }
    ## (3) Actually call the function on both primary and js levels, and save the values.
    primary_indicators = primary_and_junior_sec_indicators(education_data, 'primary')
    js_indicators = primary_and_junior_sec_indicators(education_data, 'junior')
    ## (4) Make overall indicators (ie, ones that are not specific to each level).
    lga_data = education_data %.% group_by(lga) %.% 
        dplyr::summarise(
            num_senior_secondary_schools = sum(str_detect(facility_type, 'senior_sec')),
            num_schools = n(),
            percent_management_public = mean(is_public, na.rm=T),
            pupil_teachers_ratio_lga = ratio(num_students_total, num_tchr_full_time),
            percent_natl_curriculum = mean(natl_curriculum_yn, na.rm=T)) 
    ## (5) Join everything together
    lga_data %.% 
        inner_join(primary_indicators, by='lga') %.%
        inner_join(js_indicators, by='lga') %.%
    ## (6) Rename some of our indicators to possibly non-standard form. (Should go away).
        select(##RENAMING BEFORE RETURNING: NOTE THESE SHOULD BE CHANGED ONCE 774 + MOPUP ARE TOGETHER
            num_primary_schools = num_schools_primary,
            num_junior_secondary_schools = num_schools_js,
            pupil_toilet_ratio_secondary = pupil_toilet_ratio_js,
            proportion_schools_chalkboard_all_rooms_juniorsec = proportion_schools_chalkboard_all_rooms_js,
            primary_school_pupil_teachers_ratio_lga = pupil_teachers_ratio_lga_primary,
            student_classroom_ratio_lga_juniorsec = student_classroom_ratio_lga_js,
            junior_secondary_school_pupil_teachers_ratio_lga = pupil_teachers_ratio_lga_js,
            proportion_teachers_nce_juniorsec = proportion_teachers_nce_js,
            student_teacher_ratio_lga = pupil_teachers_ratio_lga,
            matches('.')
        )
}

## Health Facilities LGA-level indicators for mopup
## The way this works, roughly is:
## (1) Create additional facility-level indicators that are helpful in our later calculations
## (2-4) Create three different aggregated datasets. One will be just the aggregations for hospital,
##       another one for all but health posts, and final aggregated dataset for all facilities.
## (5) Merge our three aggregated datasets by lga, and return.
health_mopup_lga_indicators = function(health_data) {
    ## (1) Definitions to help us make indicators later on
    health_data = health_data %.% mutate(
        is_public = management %in% c('federal_gov', 'local_gov', 'state_gov'),
        is_hospital = str_detect(facility_type, 'hospital'),
        is_healthpost = facility_type %in% c('dispensary', 'health_post'),
        is_healthfacility = ! (facility_type %in% c('dk', 'none')),
        is_allExceptHealthPost = is_healthfacility & ! is_healthpost
    #    alternative_functional_power = # either have functional generator, or functional solar
    #        ifelse(power_sources.generator, generator_functional=='yes', FALSE) |
    #        ifelse(power_sources.solar_system, solar_functional=='yes', FALSE)
    )
    ## (2) Aggregation 1: Services that are provided at Hospitals only
    hospital_data = health_data %.% filter(is_hospital) %.% group_by(lga) %.% 
        dplyr::summarise(
            num_hospitals = n(),
            percent_compr_oc_c_sections = mean(c_section_yn == 'yes'))
    ## (3) Aggregation 2: Services that are provided at all facilties except for Health Posts
    allExceptHealthPost_data = health_data %.% filter(is_allExceptHealthPost) %.% group_by(lga) %.%
        dplyr::summarise(
            num_health_facilities_sansHP = n(),
            proportion_delivery_24_7_sansHP = mean(maternal_health_delivery_services == 'yes', na.rm=T),
            proportion_vaccines_fridge_freezer_sansHP = mean(vaccines_fridge_freezer, na.rm=T))
    ## (4) Aggregation 3: Services that are provided at all facilities including Health Posts
    allFacilities_data = health_data %.% filter(is_healthfacility) %.% group_by(lga) %.%
        dplyr::summarise(
            num_health_facilities = n(),
            proportion_antenatal = mean(antenatal_care_yn == 'yes', na.rm=T),
            proportion_family_planning = mean(family_planning_yn == 'yes', na.rm=T),
            proportion_access_functional_emergency_transport = mean(emergency_transport == 'yes', na.rm=T),
            proportion_act_treatment_for_malaria = mean(malaria_treatment_artemisinin == 'yes', na.rm=T),
            proportion_measles = mean(child_health_measles_immun_calc == 'yes', na.rm=T),
            
            ## Facilities
            num_facilities = n(),
            num_level_1_health_facilities = sum(is_healthpost, na.rm=T),
            num_level_2_health_facilities = sum(facility_type == 'basic_health_centre', na.rm=T),       
            num_level_3_health_facilities = sum(facility_type == 'primary_health_centre', na.rm=T),
            num_level_4_health_facilities = sum(is_hospital, na.rm=T),
            
            ## Staffing
            num_doctors = sum(num_doctors_fulltime, na.rm=T),
            num_nurses = sum(num_nurses_fulltime, na.rm=T),
            num_chews = sum(num_chews_fulltime, na.rm=T),
            num_nursemidwives_midwives = sum(num_nursemidwives_fulltime, na.rm=T),
            
            ## Overview Tab
            facilities_delivery_services_yn = sum(maternal_health_delivery_services == 'yes', na.rm=T),
            facilities_emergency_transport = sum(emergency_transport == 'yes', na.rm=T),
            facilities_skilled_birth_attendant = sum(skilled_birth_attendant, na.rm=T),
            facilities_measles = sum(child_health_measles_immun_calc == 'yes', na.rm=T),
            
            ## Infrastructure -- all facilities
            proportion_improved_water_supply = mean(improved_water_supply, na.rm=T),
            proportion_improved_sanitation = mean(improved_sanitation, na.rm=T),
            proportion_phcn_electricity = mean(phcn_electricity, na.rm=T))
#             proportion_power_alternative_functional = mean(alternative_functional_power, na.rm=T))
     ## (5) Merge everything (merge is equivalent to left_join in dplyr) and return
     return(allFacilities_data %.% 
                left_join(allExceptHealthPost_data, by='lga') %.% 
                left_join(hospital_data, by='lga'))
}
