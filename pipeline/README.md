Instructions on running the pipeline.

(1) Install R, and run the following on the R console to install required packages:
```
install.packages(c("devtools", "dplyr"))
require(devtools)
install_github('formhub.R', 'SEL-Columbia')
```

(2) Make the following directories inside pipeline: `data`, `data/output_data`.

(3) Edit CONFIG.JSON and put in the appropriate directories where data live.
Example from one machine:
```
{
    NMIS_774_FACILITY_DATA: "~/Dropbox/Nigeria/Nigeria 661 Baseline Data Cleaning/in_process_data/nmis/Normalized/",
    NMIS_REPO: "~/Code/nmis",
    AUTHFILE: "authfile"
}
```
Note that authfile should be a file that has nothing but
FORMHUB_USERNAME:FORMHUB_PASSWORD

(3) For each of the following purposes, run the corresponding command:
 * Download data from formhub: `Rscript Download.R`
 * Run facility level transformations: `Rscript DoFacilityTransformations.R`
 * Run lga level aggregations: `Rscript DoAggregations.R` 
