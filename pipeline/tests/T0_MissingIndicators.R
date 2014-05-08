# RUN THIS FILE from the pipeline directory; on the command line:
# R CMD BATCH test/T0_MissingIndicators.R /dev/tty
source('nmis_functions.R'); source('CONFIG.R')
suppressPackageStartupMessages(require(testthat))

required_indicators = get_necessary_indicators()

## Check missing indicators according to the passed in indicators
missing_indicators = function(df, nmis_indicators, sector) {
    sector_indicators = nmis_indicators[[sector]]
    return(sector_indicators[!sector_indicators %in% names(df)])
}

test_that('Required Facility Level Indicators are not missing.', {
    output_file <- function(file) { sprintf("%s/%s", CONFIG$OUTPUT_DIR, file) }
    (e_miss <- missing_indicators(read.csv(output_file("Education_Mopup_and_Baseline_NMIS_Facility.csv")), 
        required_indicators$facility, 'education'))
    (h_miss <- missing_indicators(read.csv(output_file("Health_Mopup_and_Baseline_NMIS_Facility.csv")), 
        required_indicators$facility, 'health'))
    expect_equivalent(character(0), e_miss)
    expect_equivalent(character(0), h_miss)
})

test_that('Required LGA Indicators are not missing.', {
    output_file <- function(file) { sprintf("%s/%s", CONFIG$OUTPUT_DIR, file) }
    (e_miss <- missing_indicators(read.csv(output_file("Education_Mopup_and_Baseline_LGA_Aggregations.csv")), 
        required_indicators$lga, 'education'))
    (h_miss <- missing_indicators(read.csv(output_file("Health_Mopup_and_Baseline_LGA_Aggregations.csv")), 
        required_indicators$lga, 'health'))
    expect_equivalent(character(0), e_miss)
    expect_equivalent(character(0), h_miss)
})
