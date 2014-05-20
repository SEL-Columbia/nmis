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
education_mopup_lga_indicators <- function(education_data) {
    ## (0) WE will list out which types are which here:
    TYPES = list("primary" = c("preprimary_and_primary", "primary_only"),
                 "junior_sec" = c("junior_sec_only"),
                 "combined" = c("primary_and_junior_sec", "primary_junior_and_senior_sec",
                                  "junior_and_senior_sec"))
    ## (1) Create additional facility-level indicators that are helpful in our later calculations
    education_data <- education_data %.% mutate(
        ## TYPES: primary and js are double-counted, plus we have a "combined" type
        is_primary = facility_type %in% TYPES$primary,
        is_junior_secondary = facility_type %in% TYPES$junior_sec, 
        is_combined = facility_type %in% TYPES$combined,
        management = revalue(management, c("federal_gov"="public", "local_gov" = "public",
                                           "state_gov" = "public")),
        is_valid_facility = ! facility_type %in% c('dk', 'none', 'DROP')
    )
    ## (2) Define a function which will calculate indicators given a "level". Level is primary or junior.
    ## primary and junior secondary indicator transformations. Note: columns will end with _primary or _js
    primary_and_junior_sec_indicators <- function(data, level) {
        stopifnot(level %in% c("primary", "junior_sec")) # make sure level is either Primary or Junior
        data <- data %.% 
            group_by(unique_lga) %.% 
            filter(facility_type %in% TYPES[[level]]) %.% ## subset for this level only
            dplyr::summarize(
                num_schools = n(),
                ## Average indicators (make sure to round)
                avg_num_tchrs = round(mean(num_tchr_full_time, na.rm=T)),
                avg_num_students = round(mean(num_students_total, na.rm=T)),
                avg_num_classrms = round(mean(num_classrms_total, na.rm=T)),
                avg_num_toilets = round(mean(num_toilets_total, na.rm=T)),
                ## Percent indicators
                percent_management_public = percent(management == "public"),
                percent_natl_curriculum = percent(natl_curriculum_yn),
                percent_functional_water = percent(functional_water),
                percent_schools_chalkboard_all_rooms = percent(chalkboard_each_classroom_yn),
                percent_improved_sanitation = percent(improved_sanitation),
                percent_phcn_electricity = percent(phcn_electricity),
                ## The following are "ratio" indicators
                pupil_toilet_ratio = ratio(num_students_total, num_toilets_total),
                student_classroom_ratio_lga = ratio(num_students_total, num_classrms_total),
                percent_teachers_nce = ratio(num_tchrs_with_nce, num_tchr_full_time, as.percent=TRUE),
                pupil_teachers_ratio_lga = ratio(num_students_total, num_tchr_full_time)
            )
        ## Rename our indicators to end with _primary and _js. Note: don't rename lga, which is the first column.
        level_suffix = c('primary' = 'primary', 'junior_sec' = 'js')[level]
        names(data)[-1] <- paste(names(data)[-1], level_suffix, sep="_")
        return(data)
    }
    ## (3) Actually call the function on both primary and js levels, and save the values.
    primary_indicators = primary_and_junior_sec_indicators(education_data, 'primary')
    js_indicators = primary_and_junior_sec_indicators(education_data, 'junior_sec')
    ## (4) Make overall indicators (ie, ones that are not specific to each level).
    lga_data = education_data %.% filter(is_valid_facility) %.% group_by(unique_lga) %.% 
        dplyr::summarise(
            num_schools = n(),
            percent_management_public = percent(management == "public"),
            pupil_teachers_ratio_lga = ratio(num_students_total, num_tchr_full_time),
            num_informal_schools = sum(!natl_curriculum_yn, na.rm=T),
            percent_natl_curriculum = percent(natl_curriculum_yn)) 
    ## (5) Join everything together
    lga_data %.% 
        inner_join(primary_indicators, by='unique_lga') %.%
        inner_join(js_indicators, by='unique_lga') %.%
    ## (6) Rename some of our indicators to possibly non-standard form. (Should go away).
        dplyr::select(##RENAMING BEFORE RETURNING: NOTE THESE SHOULD BE CHANGED ONCE 774 + MOPUP ARE TOGETHER
            num_primary_schools = num_schools_primary,
            num_junior_secondary_schools = num_schools_js,
            proportion_schools_chalkboard_all_rooms_juniorsec = percent_schools_chalkboard_all_rooms_js,
            proportion_schools_chalkboard_all_rooms_primary = percent_schools_chalkboard_all_rooms_primary,
            proportion_teachers_nce_primary = percent_teachers_nce_primary,
            proportion_teachers_nce_js = percent_teachers_nce_js,
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
        is_healthfacility = ! (facility_type %in% c('dk', 'none') | is.na(facility_type)),
        is_allExceptHealthPost = is_healthfacility & ! is_healthpost
    )
    ## (2) Aggregation 1: Services that are provided at Hospitals only
    hospital_data = health_data %.% filter(is_hospital) %.% group_by(unique_lga)  %.% 
         dplyr::summarise(
             percent_csection = percent(c_section_yn))
    ## (3) Aggregation 2: Services that are provided at all facilties except for Health Posts
    allExceptHealthPost_data = health_data %.% filter(is_allExceptHealthPost) %.% group_by(unique_lga) %.%
        dplyr::summarise(
            proportion_delivery_sansHP = percent(maternal_health_delivery_services),
            proportion_vaccines_fridge_freezer_sansHP = percent(vaccines_fridge_freezer))
    ## (4) Aggregation 3: Services that are provided at all facilities including Health Posts
    allFacilities_data = health_data %.% filter(is_healthfacility) %.% group_by(unique_lga) %.%
        dplyr::summarise(
            num_health_facilities = n(),
            proportion_antenatal = percent(antenatal_care_yn),
            proportion_family_planning = percent(family_planning_yn),
            proportion_access_emergency_transport = percent(emergency_transport),
            proportion_act_treatment_for_malaria = percent(malaria_treatment_artemisinin),
            proportion_measles = percent(child_health_measles_immun_calc),
            
            ## Facilities
            num_health_facilities = n(),
            num_level_1_health_facilities = sum(is_healthpost, na.rm=T),
            num_level_2_health_facilities = sum(facility_type == 'basic_health_centre', na.rm=T),       
            num_level_3_health_facilities = sum(facility_type == 'primary_health_centre', na.rm=T),
            num_level_4_health_facilities = sum(is_hospital, na.rm=T),
            num_hospitals = sum(is_hospital, na.rm=T),
            num_health_facilities_sansHP = sum(is_allExceptHealthPost, na.rm=T),
            
            ## Staffing
            num_doctors = sum(num_doctors_fulltime, na.rm=T),
            num_nurses = sum(num_nurses_fulltime, na.rm=T),
            num_chews = sum(num_chews_fulltime, na.rm=T),
            num_nursemidwives_midwives = sum(num_nursemidwives_fulltime, na.rm=T),
            
            ## Overview Tab
            facilities_delivery_services_yn = sum(maternal_health_delivery_services, na.rm=T),
            facilities_emergency_transport = sum(emergency_transport, na.rm=T),
            facilities_skilled_birth_attendant = sum(skilled_birth_attendant, na.rm=T),
            facilities_measles = sum(child_health_measles_immun_calc, na.rm=T),
            
            ## Infrastructure -- all facilities
            proportion_improved_water_supply = percent(improved_water_supply),
            proportion_improved_sanitation = percent(improved_sanitation),
            proportion_phcn_electricity = percent(phcn_electricity),
            proportion_access_to_alternative_power = percent(access_to_alternative_power_source))
     ## (5) Merge everything (merge is equivalent to left_join in dplyr) and return
     return(allFacilities_data %.% 
                left_join(allExceptHealthPost_data, by='unique_lga') %.% 
                left_join(hospital_data, by='unique_lga'))
}

water_lga_indicators <- function(water_data) {
    ## all calculation are gathered from 
    ## nmis_R_scripts/nmis/nmis_indicators_water_lga_level_normalized.R
    lga_data = water_data %.% group_by(unique_lga) %.% 
        dplyr::summarise(
            ## Water Point Type
            num_total_water_points = n(),
            num_taps =  sum(water_point_type == "Tap", na.rm = T),
            num_unimproved_points = sum(!is_improved, na.rm = T),
            num_overhead_tanks = sum(water_point_type
                %in% c("Overhead Tank", "Rainwater Harvesting System"), na.rm = T),
            num_handpumps = sum(water_point_type %in% c('Borehole', 'Handpump'), na.rm = T),
            num_improved_water_points = sum(is_improved, na.rm = T),

            ## Functionality
            percentage_functional_improved = percent(functional, filter = is_improved),
            percentage_functional_handpumps = percent(functional, filter = water_point_type %in% c("Handpump", "Borehole")),
            percentage_functional_taps = percent(functional, water_point_type == "Tap"),

            ## Lift Mechanism Analysis
            num_diesel = sum(lift_mechanism == "Diesel", na.rm = T),
            percentage_diesel_functional = percent(functional, lift_mechanism == "Diesel"),
            num_electric = sum(lift_mechanism == "Electric", na.rm = T),
            percentage_electric_functional = percent(functional, lift_mechanism == "Electric"),
            num_solar = sum(lift_mechanism == "Solar", na.rm = T),
            percentage_solar_functional = percent(functional, lift_mechanism == "Solar")
        )

     return(lga_data) 
}

education_gap_sheet_indicators <- function(education_data) {
    ## (0) WE will list out which types are which here:
    TYPES = list("primary" = c("preprimary_and_primary", "primary_only"),
                 "junior_sec" = c("junior_sec_only"),
                 "combined" = c("primary_and_junior_sec", "primary_junior_and_senior_sec",
                                "junior_and_senior_sec"))
    ## (1) Create additional facility-level indicators that are helpful in our later calculations
    education_data %.% 
        mutate(
            is_primary_or_js = facility_type %in% c(TYPES$primary, TYPES$junior_sec)
        ) %.% 
    ## (2) Filter by just primary and junior secondary schools and group by lga
        filter(is_primary_or_js) %.%
        group_by(unique_lga) %.%
    ## (3) And finally, create the summary indicators
        dplyr::summarize(
            primary_js = n(),
            num_existing_classrooms = sum(num_classrms_total, na.rm=T),
            total_teachers = sum(num_tchr_full_time, na.rm=T),
            improved_functional_water = percent(improved_water_supply),
            improved_sanitation = percent(improved_sanitation),
            phcn_electricity_e = percent(phcn_electricity),
            num_classrms_repairs = 
                ratio(num_classrms_repair, num_classrms_total, as.percent=TRUE),
            num_classrm_w_chalkboard = 
                ratio(num_classrm_w_chalkboard, num_classrms_total, as.percent=TRUE),
            num_tchrs_with_nce = 
                ratio(num_tchrs_with_nce, num_tchr_full_time, as.percent=TRUE)
        )
    ## (4) Final step for gap sheets. Note that we want to output data as numerator / denominator
    ## rather than percent for gap sheets. We do the splitting below. TODO
}

health_gap_sheet_indicators <- function(health_data) {
    ## (1) Definitions to help us make indicators later on
    health_data = health_data %.% mutate(
        is_public = management %in% c('federal_gov', 'local_gov', 'state_gov', 'public'),
        is_hospital = str_detect(facility_type, 'hospital'),
        is_healthpost = facility_type %in% c('dispensary', 'health_post'),
        is_phcentre = facility_type %in% c('primary_health_centre'),
        is_phclinic = facility_type %in% c('basic_health_centre'),
        is_healthfacility = ! (facility_type %in% c('dk', 'none') | is.na(facility_type)),
        is_allExceptHealthPost = is_healthfacility & ! is_healthpost,
        is_hospital_phc_or_clinic = is_hospital | is_phcentre | is_phclinic,
        num_skilled_birth_attendants = rowSums(cbind(num_nursemidwives_fulltime, num_doctors_fulltime), na.rm=T)
    )
    ## (2) Aggregation 1: Services that are provided at Hospitals only
    hospital_data = health_data %.% 
        filter(is_hospital) %.% 
        group_by(unique_lga)  %.% 
        dplyr::summarise(
            c_section_yn = percent(c_section_yn)
        )
    ## (3) Aggregation 2: Services that are provided at all facilties except for Health Posts
    hospital_phc_clinic_data = health_data %.% 
        filter(is_hospital_phc_or_clinic) %.% 
        group_by(unique_lga) %.%
        dplyr::summarise(
            i_water_supply = percent(improved_water_supply),
            i_sanitation = percent(improved_sanitation),
            phcn_electricity_h = percent(phcn_electricity),
            any_power_available = percent(phcn_electricity | access_to_alternative_power_source),        
            sba = percent(num_skilled_birth_attendants >= 2),
            delivery_services_yn = percent(maternal_health_delivery_services),
            vaccines_fridge_freezer = percent(vaccines_fridge_freezer)
        )
    ## (4) Aggregation 3: Services that are provided at all facilities including Health Posts
    allFacilities_data = health_data %.% 
        filter(is_healthfacility) %.% 
        group_by(unique_lga) %.%
        dplyr::summarise(
            total_facilities = sum(is_healthfacility, na.rm=T),
            total_hospitals = sum(is_hospital, na.rm=T),
            total_phcentres = sum(is_phcentre, na.rm=T),
            total_phclinics = sum(is_phclinic, na.rm=T),
            total_dispensary = sum(is_healthpost, na.rm=T),
            total_sec_tertiary = 0,
            
            ## fully staffed indicators:
            phcentre = percent(num_skilled_birth_attendants >= 5 & num_chews_fulltime >= 9,
                               filter = is_phcentre),
            phclinic = percent(num_skilled_birth_attendants >= 2 & num_chews_fulltime >= 4,
                               filter = is_phclinic),
            dispensary = percent(num_chews_fulltime >= 1, filter = is_healthpost),
            
            emerg_tran = percent(emergency_transport),
            antenatal_care_yn = percent(antenatal_care_yn),
            family_planning_yn = percent(family_planning_yn),
            medication_anti_malarials = percent(malaria_treatment_artemisinin),
            child_health_measles_immun = percent(child_health_measles_immun_calc)
        )
    return(allFacilities_data %.% 
               left_join(hospital_phc_clinic_data, by='unique_lga') %.% 
               left_join(hospital_data, by='unique_lga'))
}
