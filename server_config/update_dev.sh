#!/bin/bash

# Update NMIS repo
cd /home/ubuntu/srv/nmis
git pull

# Update NMIS data
cd /home/ubuntu/srv/nmis_ui_data_2ef92c15
cd data_774

# Run csv2json if needed
git_status=`git status . -s | wc -l`
if [ $git_status -ne 0 ]; then
    cd ..
    git pull
    python csv2json.py >> /tmp/csv2json.log 2>&1
fi


