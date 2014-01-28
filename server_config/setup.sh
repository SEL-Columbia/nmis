current_dir=$(pwd)
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
# check if virtualenv programm exists
check_available virtualenv
# check if nmis virtualenv exists
echo -n "check if .nmis_virtualenv folder exists..."
virtualenv_folder=$(pwd)/../.nmis_virtualenv
if [ ! -d $virtualenv_folder ]; then
    echo "no."
    echo -n "Creating nmis virtualenv directory..."
    virtualenv $virtualenv_folder
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
    sudo cp $current_dir/nmis.nginx $sites_available
    echo "done."
fi
if [ ! -f $sites_enabled ]; then
    echo -n "creating symlink from sites-available to sites-enabled..."
    sudo ln -s $sites_available $sites_enabled
    echo "done."
fi
echo "nginx is set up"

## check if uwsgi is available
check_available uwsgi

if ! check_running uwsgi; then
    echo -n "starting uwsgi..."
    uwsgi --ini $current_dir/uwsgi.ini
    echo "done."
fi
if ! check_running nginx; then
    echo -n "staring nginx..."
    sudo service nginx start 
    echo "done."
fi
    

