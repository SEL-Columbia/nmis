#!/bin/bash
BASEDIR=$(dirname $0)
check_available () {
    echo -n "checking if $1 exists..."
    if [ $(which $1) = "" ]; then
        echo "no."
        echo "Please install $1 then restart the script."
        exit 1
    else
        echo "yes."
    fi
}
check_running () {
    echo -n "checking if $1 is running..."
    ps cax | grep $1 > /dev/null
    if [ $? -eq 0 ]; then
        echo "yes."
        return 0
    else
        echo "no."
        return 1
    fi

}


write_uwsgi_ini ()
{
#uwsgi.ini appears to only work with absolute directory 
#and file paths. Relative paths would not do.

script_uri=$(readlink -f $0)
script_dir=`dirname $script_uri`
nmis_dir="$(dirname "$script_dir")"
file_name="uwsgi.ini"
file_uri=$script_dir/$file_name


if [ -f $file_uri ]; then
echo -n "Overwriting $file_name..."
else
echo -n "Creating $file_name..."
fi

#writing to uwsgi.ini
echo "[uwsgi]" > $file_uri
echo "socket=/tmp/uwsgi.sock" >> $file_uri
echo "plugin=python" >> $file_uri
echo "processes=1" >> $file_uri
echo  "pidfile=uwsgi.pid" >> $file_uri
echo  "chdir=$nmis_dir" >> $file_uri
echo  "virtualenv=$nmis_dir/.nmis_virtualenv" >> $file_uri
echo  "module=main" >> $file_uri
echo  "daemonize = $script_dir/uwsgi.log" >> $file_uri
echo  "callable=app" >> $file_uri

echo   "done"
}


# check if virtualenv programm exists
check_available virtualenv
# check if nmis virtualenv exists
echo -n "check if .nmis_virtualenv folder exists..."
virtualenv_folder=$BASEDIR/../.nmis_virtualenv
if [ ! -d $virtualenv_folder ]; then
    echo "no."
    echo -n "Creating nmis virtualenv directory..."
    virtualenv $virtualenv_folder
    source $virtualenv_folder/bin/activate
    pip install flask
    deactivate
    echo "done."
else
    echo "yes."
fi

# set up nginx for nmis
## check if nginx is available
check_available nginx

sites_available=/etc/nginx/sites-available/nmis
sites_enabled=/etc/nginx/sites-enabled/nmis
echo "check if nginx config is set up"
if [ ! -f $sites_available ]; then
    echo -n "copying nmis.nginx config to nginx folder..."
    sudo cp $BASEDIR/nmis.nginx $sites_available
    echo "done."
fi
if [ ! -f $sites_enabled ]; then
    echo -n "creating symlink from sites-available to sites-enabled..."
    sudo ln -s $sites_available $sites_enabled
    echo "done."
fi
echo "nginx is set up"

##Write or overwrite the uwsgi.ini file
write_uwsgi_ini

## check if uwsgi is available
check_available uwsgi

if ! check_running uwsgi; then
    echo -n "starting uwsgi..."
    uwsgi --ini $BASEDIR/uwsgi.ini
    echo "done."
fi
if ! check_running nginx; then
    echo -n "staring nginx..."
    sudo service nginx start 
    echo "done."
fi
    

