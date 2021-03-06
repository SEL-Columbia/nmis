source('CONFIG.R')                                  ## Helps make sure its run from the right directory
suppressPackageStartupMessages(require(formhub))    ## suppressPackageStartupMessages loads packages silently 
suppressPackageStartupMessages(require(testthat))

####### TEST EDUCATION #######
test_that("LGA indicators match for education for Zurmi", {
    expected_lga_output_e = read.csv("tests/test_data/Education_NMIS_LGA_Indicators_SUBSET_zamfara_zurmi.csv")
    ### (1) PIPELINE: normalize; facility level; lga level
    test_education_data <- formhubRead("tests/test_data/education_mopup_SUBSET_zamfara_zurmi.csv",
                                      "tests/test_data/education_mopup.json", na.strings=c("999", "9999", "n/a"),
                                      keepGroupNames=F)
    source('CONFIG.R'); source('0_normalize.R'); source('3_facility_level.R'); source('4_lga_level.R')
    edu <- normalize_mopup(test_education_data, "mopup_new", "education")
    edu <- education_mopup_facility_level(edu)
    edu_lga <- education_mopup_lga_indicators(edu) %.% select(lga = unique_lga, matches('.'))
    ### (2) Test that they are the same
    
    ## Sanity checks
    expect_true(nrow(edu_lga) == 1) # we should produce only one column
    #expect_equivalent(setdiff(names(edu_lga), names(expected_lga_output_e)),
    #                  character(0)) # all columns should be in test data
    
    ## Convert things from x% (y out of z) to just x, which is what it looks like for expected_output
    edu_lga[-1] <- colwise(as.numeric)(colwise(function(x) { str_extract(x, '[0-9]*')})(edu_lga[-1]))
    education_indicators <- intersect(names(expected_lga_output_e), names(edu_lga))
    should_eq <- rbind(expected_lga_output_e[education_indicators], edu_lga[education_indicators])
    
    ## For debugging, print out should_eq, should_eq[should_eq[1,] != should_eq[2,]]
    #expect_true(all(should_eq[1,] == should_eq[2,], na.rm=T))    
})

test_that("Education, num_schools match for Kano Shanono", {
    test_education_data_ks <- tbl_df(read.csv("tests/test_data/Education_m+b_Kano_Shanono.csv",
                                    stringsAsFactors = F))
    source('4_lga_level.R')
    ks_lga <- education_mopup_lga_indicators(test_education_data_ks)
   
    ## See https://github.com/SEL-Columbia/nmis/issues/198
    expected_data <- data.frame(unique_lga = "kano_shanono", 
                                num_primary_schools = 84,
                                num_junior_secondary_schools = 8,
                                num_combined_schools = 4,
                                num_informal_schools = 49,
                                num_schools = 145)
    
    ks_lga <- ks_lga[names(expected_data)]
    expect_true(all(ks_lga == expected_data))
})

####### TEST HEALTH #######
test_that("LGA indicators match for health for Zurmi", {
    expected_lga_output_h = read.csv("tests/test_data/Health_NMIS_LGA_Indicators_SUBSET_zamfara_zurmi.csv")
    ### (1) PIPELINE: normalize; facility level; lga level
    test_health_data <- formhubRead("tests/test_data/health_mopup_SUBSET_zamfara_zurmi.csv",
                                   "tests/test_data/health_mopup.json", na.strings=c("999", "9999", "n/a", "NA"),
                                   keepGroupNames=F)
    source('CONFIG.R'); source('0_normalize.R'); source('3_facility_level.R'); source('4_lga_level.R')
    health <- normalize_mopup(test_health_data, "mopup_new", "health")
    health <- health_mopup_facility_level(health)
    health_lga <- health_mopup_lga_indicators(health) %.% 
        select(lga = unique_lga, matches('.')) %.% filter(lga != "DISCARD") ## we had to insert
    ### (2) Test that they are the same
    ## Sanity checks
    expect_true(nrow(health_lga) == 1) # we should produce only one column
    expect_equivalent(setdiff(names(health_lga), names(expected_lga_output_h)),
                      character(0)) # all columns should be in test data
    
    ## Convert things from x% (y out of z) to just x, which is what it looks like for expected_output
    health_lga[-1] <- colwise(as.numeric)(colwise(function(x) { str_extract(x, '[0-9]*')})(health_lga[-1]))
    health_indicators <- intersect(names(expected_lga_output_h), names(health_lga))
    should_eq <- rbind(expected_lga_output_h[health_indicators], health_lga[health_indicators])
    ## For debugging, print out should_eq, should_eq[1,] - should_eq[2,]
    expect_true(all(should_eq[1,] == should_eq[2,], na.rm=T))    
})

test_that("Mopup Integration pipeline reproduces baseline aggregations for health", {
    source('CONFIG.R'); source("0_normalize.R"); source("4_lga_level.R")
    test_health_data <- tbl_df(readRDS(CONFIG$BASELINE_HEALTH)) %.%
        normalize_2012(survey_name="2012", sector="health")
    health_lga <- health_mopup_lga_indicators(test_health_data)
    
    expected_lga_output <- tbl_df(readRDS(CONFIG$BASELINE_ALL_774_LGA))
    percent_indicators <- names(expected_lga_output)[str_detect(names(expected_lga_output), 'proportion|percent')]
    expected_lga_output[percent_indicators] <- colwise(function(x) {round(100*x)})(expected_lga_output[percent_indicators])
    
    
    # Modify the expected output a bit, because indicator definitions have changed quite a bit
    expected_lga_output <- expected_lga_output %.% 
        # Do some renaming of indicators, when the names changed for clarity (but definitions haven't changed)
        dplyr::select( ## RENAME 2012 LGA indicators to match up with integrated version
            percent_improved_water = proportion_improved_water_supply,
            percent_improved_sanitation = proportion_improved_sanitation,
            matches('.')
        )
    
   
    ## Convert things from x% (y out of z) to just x, which is what it looks like for expected_output
    non_lga_cols <- setdiff(names(health_lga), c("lga"))
    health_lga[non_lga_cols] <- colwise(as.numeric)(colwise
                                                       (function(x) { str_extract(x, '[0-9]*')})(health_lga[non_lga_cols]))
    health_indicators <- intersect(names(expected_lga_output), names(health_lga))

    cat(".. Ignoring changed/new Indicators: ", setdiff(names(health_lga), health_indicators), "\n")
    
    for(lg in intersect(expected_lga_output$lga, health_lga$lga)) {
        # (lg = "Zaria")
        # (lg = sample(intersect(expected_lga_output$lga, health_lga$lga), 1))
        if(!is.na(expected_lga_output$num_level_other_health_facilities) &
               expected_lga_output$num_level_other_health_facilities == 0) {
            (should_eq <- data.frame(rbind(subset(expected_lga_output, lga == lg, select=health_indicators), 
                       subset(health_lga, lga == lg, select=health_indicators))))
            ## For debugging, print out should_eq OR should_eq[1,] - should_eq[2,]
            expect_true(all(should_eq[1,] == should_eq[2,], na.rm=T))
        }
    }
})


test_that("Mopup Integration pipeline reproduces baseline aggregations for education", {
    source("CONFIG.R"); source("0_normalize.R"); source("4_lga_level.R")
    test_education_data <- tbl_df(readRDS(CONFIG$BASELINE_EDUCATION)) %.%
        normalize_2012(survey_name="2012", sector="education")
    education_lga <- education_mopup_lga_indicators(test_education_data)
    
    expected_lga_output <- tbl_df(readRDS(CONFIG$BASELINE_ALL_774_LGA))
    percent_indicators <- names(expected_lga_output)[str_detect(names(expected_lga_output), 'proportion|percent')]
    expected_lga_output[percent_indicators] <- colwise(function(x) {round(100*x)})(expected_lga_output[percent_indicators])
    avg_ratio_indicators <- names(expected_lga_output)[str_detect(names(expected_lga_output), 'avg|ratio')]
    expected_lga_output[avg_ratio_indicators] <- colwise(function(x) {round(x)})(expected_lga_output[avg_ratio_indicators])
    
    # Modify the expected output a bit, because indicator definitions have changed quite a bit
    expected_lga_output <- expected_lga_output %.% 
        # Only two LGAs are comparable, since they have only primary_only + js_only schools
        filter(lga %in% c("Guzamala", "Illela")) %.%
        # Do some renaming of indicators, when the names changed for clarity (but definitions haven't changed)
        dplyr::select( ## RENAME 2012 LGA indicators to match up with integrated version
            proportion_teachers_nce_js = proportion_teachers_nce_juniorsec,
            pupil_teachers_ratio_lga_primary = primary_school_pupil_teachers_ratio_lga,
            pupil_toilet_ratio_js = pupil_toilet_ratio_secondary,
            student_classroom_ratio_lga_js = student_classroom_ratio_lga_juniorsec,
            pupil_teachers_ratio_lga_js = junior_secondary_school_pupil_teachers_ratio_lga,
            percent_improved_water_primary = proportion_schools_improved_water_supply_primary,
            percent_improved_water_js = proportion_schools_improved_water_supply_juniorsec,
            matches('.')
        )
    
    ## Convert things from x% (y out of z) to just x, which is what it looks like for expected_output
    non_lga_cols <- setdiff(names(education_lga), c("lga"))
    education_lga[non_lga_cols] <- colwise(as.numeric)(colwise
        (function(x) { str_extract(x, '[0-9]*')})(education_lga[non_lga_cols]))
    education_indicators <- intersect(names(expected_lga_output), names(education_lga))
    
    cat("... Ignoring changed/new indicators: ", setdiff(names(education_lga), education_indicators), "\n")
    
    for(lg in intersect(expected_lga_output$lga, education_lga$lga)) {
        # (lg = "Zaria")
        # (lg = sample(intersect(expected_lga_output$lga, education_lga$lga), 1))
        (should_eq <- data.frame(rbind(subset(expected_lga_output, lga == lg, select=education_indicators), 
                                           subset(education_lga, lga == lg, select=education_indicators))))
        ## For debugging, print out should_eq OR should_eq[1,] - should_eq[2,]
        expect_true(all(should_eq[1,] == should_eq[2,], na.rm=T))
    }
})


test_that("number_of_toilets_is_correct_in_kebbi_shanga", {
  
  kebbi_shanga <- read.csv("tests/test_data/kebbi_toilet_test.csv")
  
  #hand calculated the total number of 0's should be 22
  
  #pipeline output
  source("nmis_functions.R");source("2_outlier_cleaning.R")
  pipeline_output <- education_outlier(kebbi_shanga)
  
  pipeline_output <- pipeline_output %.% 
    dplyr::filter(num_toilets_total == 0) 
  
  expect_equal(nrow(pipeline_output),22)
  
})
