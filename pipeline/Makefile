all: pipeline test
tests = $(shell ls tests/*.R)
pipeline data/output_data/*.csv: RunPipeline.R 0_normalize.R 2_outlier_cleaning.R 3_facility_level.R 4_lga_level.R
	R CMD BATCH --slave RunPipeline.R /dev/tty
test:
	@$(foreach test,$(tests), echo "Running $(test)"; R CMD BATCH --slave $(test) /dev/tty;)
download:
	R CMD BATCH --slave Download.R /dev/tty
