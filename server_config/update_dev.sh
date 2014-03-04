#!/bin/bash

# Update NMIS repo
cd /home/ubuntu/srv/nmis
git pull

# Update NMIS data
cd /home/ubuntu/srv/nmis_ui_data_2ef92c15

# Run csv2json if needed
git_result=`git pull | grep "^Already up-to-date." | wc -l`
if [ $git_result -eq 0 ]; then
    git pull
    python csv2json.py >> /tmp/csv2json.log 2>&1
fi


