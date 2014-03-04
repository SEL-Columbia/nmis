#!/bin/bash

# Update NMIS repo
cd /home/ubuntu/srv/nmis
git pull

# Update NMIS data and run csv2json if needed
cd /home/ubuntu/srv/nmis_ui_data_2ef92c15

git_result=`git pull | grep "^Already up-to-date." | wc -l`
if [ $git_result -eq 0 ]; then
    python csv2json.py >> /tmp/csv2json.log 2>&1
fi


