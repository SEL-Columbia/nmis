Instructions on running the pipeline.

(1) Install R, and run the following on the R console to install required packages:
```
install.packages(c("devtools", "dplyr"))
require(devtools)
install_github('formhub.R', 'SEL-Columbia')
```

(2) Make the following directories inside pipeline: `data`, `data/output_data`.

(3) Create a file called `authfile.txt`. Its content should be FORMHUB_USERNAME:FORMHUB_PASSWORD and nothing else. Example, if my formhub username is Johnny and my password is appleseed, the file should have `Johnny:appleseed` in it.

(4) Open CONFIG.R and edit the directory names to point to the right directories. An example from my machine:
```
CONFIG = list(
    BASELINE_EDUCATION="~/Dropbox/Nigeria/Nigeria 661 Baseline Data Cleaning/in_process_data/nmis/Normalized/Education_774_NMIS_Facility.rds",
    BASELINE_HEALTH="~/Dropbox/Nigeria/Nigeria 661 Baseline Data Cleaning/in_process_data/nmis/Normalized/Health_774_NMIS_Facility.rds",
    MOPUP_DATA_DIR="data", 
    OUTPUT_DIR="data/output_data",
    AUTHFILE="authfile.txt" # this is the filename that we created in step 3.
)
```

(5) For each of the following purposes, run the corresponding command in the command line (you have to be in the pipeline directory):
 * Download data from formhub: `Rscript Download.R`
 * Run facility level transformations: `Rscript DoFacilityTransformations.R`
 * Run lga level aggregations: `Rscript DoAggregations.R` 

(6) To make sure that we are calculating our indicators correctly, we have written tests for our pipeline. To run them, from the command line (in the pipeline directory), run:
 * `Rscripts tests/T1_TestLGAData.R` -- If you see errors, FIX THEM IMMEDIATELY.
