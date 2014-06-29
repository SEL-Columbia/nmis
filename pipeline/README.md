Instructions on running the pipeline.

(1) Install R, and run the following on the R console to install required packages:
```
install.packages(c("devtools", "dplyr", "testthat", "RSQLite"))
require(devtools)
install_github('formhub.R', 'SEL-Columbia')
```

(2) Make the following directories inside pipeline: `data/output_data`.

(3) Create a file called `authfile.txt`. Its content should be FORMHUB_USERNAME:FORMHUB_PASSWORD and nothing else. Example, if my formhub username is Johnny and my password is appleseed, the file should have `Johnny:appleseed` in it.

(4) Open CONFIG.R and edit the directory names to point to the right directories. An example from my machine:
```
CONFIG = list(
    BASELINE_ALL_774_LGA = "~/Dropbox/Nigeria/Nigeria 661 Baseline Data Cleaning/output_data/data_774/All_774_LGA.rds",
    BASELINE_EDUCATION="~/Dropbox/Nigeria/Nigeria 661 Baseline Data Cleaning/output_data/normalized/Education_774_NMIS_Facility.rds",
    BASELINE_HEALTH="~/Dropbox/Nigeria/Nigeria 661 Baseline Data Cleaning/output_data/normalized/Health_774_NMIS_Facility.rds",
    BASELINE_WATER="~/Dropbox/Nigeria/Nigeria 661 Baseline Data Cleaning/output_data/normalized/Water_774_NMIS_Facility.rds",
    BASELINE_EXTERNAL="~/Dropbox/Nigeria/Nigeria 661 Baseline Data Cleaning/external_data/output_data/external_data.rds",
    MOPUP_DATA_DIR="data", 
    OUTPUT_DIR="data/output_data",
    AUTHFILE="authfile.txt" # this is the filename that we created in step 3.
)
```

(5) For each of the following purposes, run the corresponding command in the command line (you have to be in the pipeline directory):
 * Run facility and lga level transformations: `make pipepline` or `Rscript RunPipeline.R`
 * Download data from formhub: `make download` or `Rscript Download.R`

(6) To make sure that we are calculating our indicators correctly, we have written tests for our pipeline. To run them, from the command line (in the pipeline directory), run:
```make test```
* this will run all the tests in the tests folder automatically
* If you see errors, FIX THEM IMMEDIATELY.

or you can run individual tests by:
```R CMD BATCH --slave tests/{name_of_test.R} /dev/tty```
Remove the --slave for more detailed output.

(7) Splitting into LGA level json files
* it is the data structure behind NMIS site
* the name comes from `unique_lga` field + `.json`
* the structure is:
    * first level are lga level indicators
    * all facility level indicators are nested as an array inside of the key "facilities"
* to run the split script, do
```python csv2json.py```
it will then create a folder `lgas` and a zipfile `nmis_data.zip`
