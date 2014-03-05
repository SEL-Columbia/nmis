#!/bin/bash

log="/tmp/update_dev.log"

date >> $log

# Update NMIS repo
cd /home/ubuntu/srv/nmis
echo "Updating NMIS repo:" >> $log
git pull >> $log

# Update NMIS data and run csv2json if needed
csv2json=`ps aux | grep "python csv2json.py" | wc -l`
if [ $csv2json -eq 1 ]; then
    echo "Updating NMIS-data repo:" >> $log
    cd /home/ubuntu/srv/nmis_ui_data_2ef92c15

    git_pull=`git pull`
    git_result=`echo $git_pull | grep "^Already up-to-date." | wc -l`
    echo $git_pull >> $log
    echo $git_result >> $log
    
    if [ $git_result -eq 0 ]; then
        echo "Running csv2json:" >> $log
        python csv2json.py >> $log

        # Remove old LGAs folder
        rm /home/ubuntu/srv/nmis/static/lgas

        # Move new LGAs folder to NMIS folder
        mv lgas /home/ubuntu/srv/nmis/static
    fi
fi


echo "--------------------------------------------------" >> $log

