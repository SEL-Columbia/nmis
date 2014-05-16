# RUN THIS FILE from the pipeline directory; on the command line:
# R CMD BATCH test/T0_MissingIndicators.R /dev/tty
source('CONFIG.R'); source('nmis_functions.R'); 
source('0_normalize.R'); source('3_facility_level.R'); source('4_lga_level.R')
suppressPackageStartupMessages(require(testthat))
suppressPackageStartupMessages(require(dplyr))

test_that('GAP Sheets are calculated as expected for education', {
    edu_2012 <- read.csv("tests/test_data/gap_sheets/2012_Baseline_Education_Illela.csv") %.%
        normalize_2012(survey_name = "2012", sector = "education")
    edu_mopup <- read.csv("tests/test_data/gap_sheets/2014_Mopup_Education_Illela.csv") %.%
        education_mopup_facility_level()
        
        
    common <- intersect(names(edu_2012), names(edu_mopup))    
    edu_all <- rbind(edu_2012[common], edu_mopup[common])
    
    education_gap_sheet <- education_gap_sheet_indicators(edu_all)
    expected_gap_sheets <- read.csv("tests/test_data/gap_sheets/edu_gap_sheet_Illela.csv",
                                    stringsAsFactors=FALSE) %.%
        mutate(percent = percent_format(numerator, denominator))
    for (indicator in expected_gap_sheets$variable) {
        if(str_detect(indicator, "gap_sheet_")) {
            bare_indicator = str_trim(str_sub(indicator, 11))
            expect_true(all(bare_indicator %in% names(education_gap_sheet)))
            expected_indicator = subset(expected_gap_sheets, variable == indicator)[,'value']
            calculated_indicator = str_extract(education_gap_sheet[,bare_indicator], '[^ ]+')
            cat(indicator, ' : ', expected_indicator, ' vs. ', calculated_indicator, '\n')
            expect_equal(expected_indicator, calculated_indicator)
        }
    }
    
})
