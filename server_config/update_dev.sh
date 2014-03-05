#!/bin/bash

# Update NMIS repo
cd /home/ubuntu/srv/nmis
git pull >> /tmp/update_dev.log

# Update NMIS data and run csv2json if needed
cd /home/ubuntu/srv/nmis_ui_data_2ef92c15


git_result=`git pull | grep "^Already up-to-date." | wc -l`
echo $git_result >> /tmp/update_dev.log 
if [ $git_result -eq 0 ]; then
    python csv2json.py >> /tmp/update_dev.log 2>&1
fi


