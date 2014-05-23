# RUN THIS FILE from the pipeline directory; on the command line:
# R CMD BATCH test/T0_MissingIndicators.R /dev/tty
source('nmis_functions.R'); source('CONFIG.R')
suppressPackageStartupMessages(require(testthat))
suppressPackageStartupMessages(require(dplyr))

output_file <- function(file) { sprintf("%s/%s", CONFIG$OUTPUT_DIR, file) }

test_that('Certain Health LGA level indicators should add up to each other', {
    health_lga <- read.csv(output_file("Health_Mopup_and_Baseline_LGA_Aggregations.csv")) 
    expectations <- health_lga %.%
        mutate(should_be_zero = (-num_health_facilities + num_level_1_health_facilities +
                                      num_level_2_health_facilities + num_level_3_health_facilities +
                                      num_level_4_health_facilities)
        )
    expect_true(all(expectations$should_be_zero == 0))
})

test_that('Number of different level schools add up to the total', {
    edu_lga <- read.csv(output_file("Education_Mopup_and_Baseline_LGA_Aggregations.csv"))
    expectations <- edu_lga %.%
        mutate(should_be_zero = (-num_schools + num_primary_schools 
                    + num_junior_secondary_schools + num_combined_schools 
                    + num_informal_schools)
        )
    expect_true(all(expectations$should_be_zero == 0))
})

test_that('LGAs.csv has exactly 774 unique LGAs, 37 (36 + FCT) states, and 6 zones, and all
          LGAs should have unique lat/lng and area', {
    lga_data <- read.csv("data/lgas.csv")
    expect_equal(length(unique(lga_data$state)), 37)
    expect_equal(length(unique(lga_data$zone)), 6)
    
    expect_equal(length(lga_data$lga_id), 774)
    expect_equal(anyDuplicated(lga_data$lga_id), 0)
    
    expect_equal(anyDuplicated(lga_data$latitude), 0)
    expect_equal(anyDuplicated(lga_data$longitude), 0)
    expect_equal(anyDuplicated(lga_data$area_sq_km), 0)
})