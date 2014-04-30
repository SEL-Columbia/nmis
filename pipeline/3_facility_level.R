require(dplyr); require(stringr); require(lubridate)

iso8601DateTimeConvert <- function(x) { ymd_hms(str_extract(x, '^[^+Z]*(T| )[^+Z-]*')) } #TODO: get rid of this

## Transformations for all facilities, mopup data, for facility level
all_mopup_facility_level = function(facility_data) {
    facility_data %.% dplyr::select(
        # RENAMING FIELDS to be nicer
        submission_time = X_submission_time, #TODO: use submission_time 
        latitude = X_gps_latitude,
        longitude = X_gps_longitude,
        matches('.')     
    ) %.% mutate(
        src = "mopup",
        # INFRASTRUCTURE
        date_of_survey = as.character(as.Date(iso8601DateTimeConvert(submission_time))), #TODO: fix
        improved_water_supply = improved_water_supply.tap | improved_water_supply.protected_well |
            improved_water_supply.rainwater | improved_water_supply.handpump,
        improved_sanitation = improved_sanitation.vip_latrine | 
            improved_sanitation.pit_latrine_with_slab | improved_sanitation.flush,
        # USEFUL DATA POINTS for DATA output, not in NMIS
        power_access = power_sources.generator | power_sources.solar_system | power_sources.grid
)}
## Transformations for education facilities, mopup data, for facility level
education_mopup_facility_level = function(education_data) {
    all_mopup_facility_level(education_data) %.% mutate(
        ## TYPE, SRC, etc.
        is_primary = str_detect(facility_type, 'primary'),
        is_junior_secondary = str_detect(facility_type, 'junior'), 
        pj = is_primary | is_junior_secondary, ## TODO: non-descriptive name
        
        ## INFRASTRUCTURE
        ## note: these are also written like this for historical consistency
        chalkboard_each_classroom_yn = num_classrm_w_chalkboard == num_classrms_total,
        functional_water = improved_water_functionality == 'functional') %.%
    select( ## RENAME
        num_tchr_full_time = num_tchrs_total,
        matches('.'))
}
## Transformations for health facilities, mopup data, for facility level
health_mopup_facility_level = function(health_data) {
    all_mopup_facility_level(health_data) %.% dplyr::select(
        # FIELDS THAT NEED RENAMING
        num_nursemidwives_fulltime = num_midwives_fulltime,
        maternal_health_delivery_services = delivery_services,
        child_health_measles_immun_calc = measles_yn,
        matches('.')
    ) %.% mutate(
        # NEWLY CALCULATED FIELDS
        skilled_birth_attendant = ((num_nursemidwives_fulltime > 0) | (num_doctors_fulltime > 0))  
    )
}
