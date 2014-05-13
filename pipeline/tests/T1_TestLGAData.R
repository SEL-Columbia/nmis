source('CONFIG.R')                                  ## Helps make sure its run from the right directory
suppressPackageStartupMessages(require(formhub))    ## suppressPackageStartupMessages loads packages silently 
suppressPackageStartupMessages(require(testthat))
expected_lga_output = read.csv("tests/test_data/mopup_NMIS_LGA_Indicators_SUBSET_zamfara_zurmi.csv")

####### TEST EDUCATION #######
test_that("LGA indicators match for education for Zurmi", {
    ### (1) PIPELINE: normalize; facility level; lga level
    test_education_data <- formhubRead("tests/test_data/education_mopup_SUBSET_zamfara_zurmi.csv",
                                      "tests/test_data/education_mopup.json", na.strings=c("999", "9999", "n/a"),
                                      keepGroupNames=F)
    source('0_normalize.R'); source('3_facility_level.R'); source('4_lga_level.R')
    edu <- normalize_mopup(test_education_data, "mopup_new")
    edu <- education_mopup_facility_level(edu)
    edu_lga <- education_mopup_lga_indicators(edu)
    ### (2) Test that they are the same
    stopifnot(nrow(edu_lga) == 1)
    education_indicators <- intersect(names(expected_lga_output), names(edu_lga))
    
    ## Convert things from x% (y out of z) to just x, which is what it looks like for expected_output
    edu_lga[-1] <- colwise(as.numeric)(colwise(function(x) { str_extract(x, '[0-9]*')})(edu_lga[-1]))
    education_indicators <- intersect(names(expected_lga_output), names(edu_lga))
    should_eq <- rbind(expected_lga_output[education_indicators], edu_lga[education_indicators])
    
    ## For debugging, print out should_eq, should_eq[should_eq[1,] != should_eq[2,]]
    expect_true(all(should_eq[1,] == should_eq[2,], na.rm=T))    
})

####### TEST HEALTH #######
test_that("LGA indicators match for health for Zurmi", {
    ### (1) PIPELINE: normalize; facility level; lga level
    test_health_data <- formhubRead("tests/test_data/health_mopup_SUBSET_zamfara_zurmi.csv",
                                   "tests/test_data/health_mopup.json", na.strings=c("999", "9999", "n/a", "NA"),
                                   keepGroupNames=F)
    source('0_normalize.R'); source('3_facility_level.R'); source('4_lga_level.R')
    health <- normalize_mopup(test_health_data, "mopup_new")
    health <- health_mopup_facility_level(health)
    health_lga <- health_mopup_lga_indicators(health) %.% filter(lga != "DISCARD") ## we had to insert
    ### (2) Test that they are the same
    stopifnot(nrow(health_lga) == 1)
    
    
    ## Convert things from x% (y out of z) to just x, which is what it looks like for expected_output
    health_lga[-1] <- colwise(as.numeric)(colwise(function(x) { str_extract(x, '[0-9]*')})(health_lga[-1]))
    health_indicators <- intersect(names(expected_lga_output), names(health_lga))
    should_eq <- rbind(expected_lga_output[health_indicators], health_lga[health_indicators])
    ## For debugging, print out should_eq, should_eq[1,] - should_eq[2,]
    expect_true(all(should_eq[1,] == should_eq[2,], na.rm=T))    
})

test_that("Mopup Integration pipeline reproduces baseline aggregations", {
    source("0_normalize.R"); source("4_lga_level.R")
    test_health_data <- tbl_df(readRDS(CONFIG$BASELINE_HEALTH)) %.%
        normalize_2012(survey_name="2012", sector="health")
    health_lga <- health_mopup_lga_indicators(test_health_data)
    
    expected_lga_output <- tbl_df(readRDS("~/Dropbox/Nigeria/Nigeria 661 Baseline Data Cleaning/in_process_data/nmis/data_774/All_774_LGA.rds"))
    percent_indicators <- names(expected_lga_output)[str_detect(names(expected_lga_output), 'proportion|percent')]
    expected_lga_output[percent_indicators] <- colwise(function(x) {round(100*x)})(expected_lga_output[percent_indicators])
   
    ## Convert things from x% (y out of z) to just x, which is what it looks like for expected_output
    health_lga[-1] <- colwise(as.numeric)(colwise(function(x) { str_extract(x, '[0-9]*')})(health_lga[-1]))
    health_indicators <- intersect(names(expected_lga_output), names(health_lga))

    cat(".. Ignoring Indicators: ", setdiff(names(health_lga), health_indicators), "\n")
    
    for(lg in intersect(expected_lga_output$lga, health_lga$lga)) {
        # (lg = "Zaria")
        #sample(intersect(expected_lga_output$lga, health_lga$lga), 1))
        if(!is.na(expected_lga_output$num_level_other_health_facilities) &
               expected_lga_output$num_level_other_health_facilities == 0) {
            (should_eq <- data.frame(rbind(subset(expected_lga_output, lga == lg, select=health_indicators), 
                       subset(health_lga, lga == lg, select=health_indicators))))
            ## For debugging, print out should_eq OR should_eq[1,] - should_eq[2,]
            expect_true(all(should_eq[1,] == should_eq[2,], na.rm=T))
        }
    }
})