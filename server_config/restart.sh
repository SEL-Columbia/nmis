#!/bin/bash
BASEDIR=$(dirname $0)
uwsgi --stop $BASEDIR/uwsgi.pid
uwsgi --ini $BASEDIR/uwsgi.ini

#restart nginx
sudo service nginx restart
