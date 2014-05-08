# RUN THIS FILE from the pipeline directory; on the command line:
# R CMD BATCH test/T0_MissingIndicators.R /dev/tty
source('nmis_functions.R'); source('CONFIG.R')
require(testthat); require(dplyr)

output_file <- function(file) { sprintf("%s/%s", CONFIG$OUTPUT_DIR, file) }

test_that('Certain Health LGA level indicators should add up to each other', {
    health_lga <- read.csv(output_file("Health_Mopup_and_Baseline_LGA_Aggregations.csv")) 
    expectations <- health_lga %.%
        mutate(expect_nums_add_up = (num_health_facilities == num_level_1_health_facilities +
                                      num_level_2_health_facilities + num_level_3_health_facilities +
                                      num_level_4_health_facilities)
        ) %.% 
        select(matches('expect'))
    expect_true(all(expectations$expect_nums_add_up))
})
