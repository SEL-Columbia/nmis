Instructions on running the pipeline.

(1) Install R, and run the following on the R console to install required packages:
```
install.packages(c("devtools", "dplyr"))
require(devtools)
install_github('formhub.R', 'SEL-Columbia')
```

(2) Make the following directories inside pipeline: `data`, `data/output_data`.

(3) Copy CONFIG.R.example to create CONFIG.R in the same directory.

(4) Open CONFIG.R and edit the directory names to point to the right directories. An example from my machine:
```
CONFIG = list(
    BASELINE_EDUCATION="~/Dropbox/Nigeria/Nigeria 661 Baseline Data Cleaning/in_process_data/nmis/Normalized/Education_774_NMIS_Facility.rds",
    BASELINE_HEALTH="~/Dropbox/Nigeria/Nigeria 661 Baseline Data Cleaning/in_process_data/nmis/Normalized/Health_774_NMIS_Facility.rds",
    MOPUP_DATA_DIR="data",
    OUTPUT_DIR="data/output_data",
    AUTHFILE="authfile"
)
```
Note that authfile should be a file that has nothing but
FORMHUB_USERNAME:FORMHUB_PASSWORD

(3) For each of the following purposes, run the corresponding command:
 * Download data from formhub: `Rscript Download.R`
 * Run facility level transformations: `Rscript DoFacilityTransformations.R`
 * Run lga level aggregations: `Rscript DoAggregations.R` 
