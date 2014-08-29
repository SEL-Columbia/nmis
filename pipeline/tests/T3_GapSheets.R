# RUN THIS FILE from the pipeline directory; on the command line:
# R CMD BATCH test/T0_MissingIndicators.R /dev/tty
suppressPackageStartupMessages(require(testthat))
suppressPackageStartupMessages(require(formhub))
suppressPackageStartupMessages(require(dplyr))
source('CONFIG.R'); source('nmis_functions.R');
source('0_normalize.R'); source('3_facility_level.R'); source('4_lga_level.R')

test_that('GAP Sheets are calculated as expected for education', {
    edu_2012 <- read.csv("tests/test_data/gap_sheets/2012_Baseline_Education_Illela.csv") %.%
        normalize_2012(survey_name = "2012", sector = "education")
    edu_mopup <- read.csv("tests/test_data/gap_sheets/2014_Mopup_Education_Illela.csv") %.%
        education_mopup_facility_level()
        
        
    common <- intersect(names(edu_2012), names(edu_mopup))    
    edu_all <- rbind(edu_2012[common], edu_mopup[common])
    
    education_gap_sheet <- education_gap_sheet_indicators(edu_all)
    expected_gap_sheets <- read.csv("tests/test_data/gap_sheets/Education_gap_sheet_Illela.csv",
                                    stringsAsFactors=FALSE)
    
    for (indicator in expected_gap_sheets$variable) {
        if(str_detect(indicator, "gap_sheet_")) {
            expected_indicator = subset(expected_gap_sheets, variable == indicator)[,'value']
            
            bare_indicator = str_trim(indicator)
            #bare_indicator = str_trim(str_sub(indicator, 11))
            
            bare_percent_indicator = str_c(bare_indicator, '_percent')
            if(bare_indicator %in% names(education_gap_sheet)) {
                calculated_indicator = as.character(education_gap_sheet[,bare_indicator])
            } else {
                expect_true(all(bare_percent_indicator %in% names(education_gap_sheet)))    
                calculated_indicator = str_c(education_gap_sheet[,bare_percent_indicator], '%')
            }
            
            #cat(indicator, ' : ', expected_indicator, ' vs. ', calculated_indicator, '\n')
            expect_equal(expected_indicator, calculated_indicator)
        }
    }
    
})

# test_that('GAP Sheets are calculated as expected for health', {
#     health_jemaa_2012 <- read.csv("tests/test_data/gap_sheets/2012_Baseline_Health_Jema_a.csv") %.%
#         normalize_2012(survey_name = "2012", sector = "health")
#     health_jemaa_mopup <- read.csv("tests/test_data/gap_sheets/2014_Mopup_Health_Jema_a.csv") %.%
#         health_mopup_facility_level()
#     
#     
#     common <- intersect(names(health_jemaa_2012), names(health_jemaa_mopup))    
#     health_jemaa_all <- rbind(health_jemaa_2012[common], health_jemaa_mopup[common])
#     
#     health_jemaa_gap_sheet <- health_gap_sheet_indicators(health_jemaa_all)
#     expected_gap_sheets <- read.csv("tests/test_data/gap_sheets/Health_gap_sheet_Jema_a.csv",
#                                     stringsAsFactors=FALSE) %.%
#         mutate(percent = percent_format(numerator, denominator))
#     for (indicator in expected_gap_sheets$variable) {
#         if(str_detect(indicator, "gap_sheet_")) {
#             expected_indicator = subset(expected_gap_sheets, variable == indicator)[,'value']
#             
#             bare_indicator = str_trim(indicator)
#             #bare_indicator = str_trim(str_sub(indicator, 11))
#             bare_percent_indicator = str_c(bare_indicator, '_percent')
#             if(bare_indicator %in% names(health_jemaa_gap_sheet)) {
#                 calculated_indicator = as.character(health_jemaa_gap_sheet[,bare_indicator])
#             } else {
#                 expect_true(all(bare_percent_indicator %in% names(health_jemaa_gap_sheet)))    
#                 calculated_indicator = str_c(health_jemaa_gap_sheet[,bare_percent_indicator], '%')
#             }
#             
#             #cat(indicator, ' : ', expected_indicator, ' vs. ', calculated_indicator, '\n')
#             expect_equal(expected_indicator, calculated_indicator)
#         }
#     }
#     
# })
