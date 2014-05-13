# Step 1: Run the pipeline.
echo "\nRunning Pipeline: RunPipeline.R"
R CMD BATCH --slave RunPipeline.R /dev/tty

# Step 2: Run the tests.
for t in $(ls tests | grep "\.R$"); do
    echo "\nRunning $t"
    R CMD BATCH --slave tests/$t /dev/tty
done
