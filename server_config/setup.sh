#!/bin/bash
BASEDIR=$(dirname $0)
check_available () {
    echo -n "checking if $1 exists..."
    if [ -z $(which $1) ]; then
        echo "no."
        echo "Please install $1 then restart the script."
        echo "in Debian or Unbuntu system, do:"
        if [ $1 == "uwsgi" ]; then
            echo "sudo apt-get install uwsgi uwsgi-plugin-python"
        else
            echo "sudo apt-get install $1"
        fi
        exit 1
    else
        echo "yes."
    fi
}

check_running () {
    echo -n "checking if $1 is running..."
    if pidof $1 > /dev/null; then
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
    script_dir=$(dirname $script_uri)
    nmis_dir=$(dirname $script_dir)
    file_name="uwsgi.ini"
    file_uri=$script_dir/$file_name
    num_cores=$(cat /proc/cpuinfo | grep processor | wc -l)


    if [ -f $file_uri ]; then
        echo -n "Overwriting $file_name..."
    else
        echo -n "Creating $file_name..."
    fi

    #writing to uwsgi.ini
    echo "[uwsgi]" > $file_uri
    echo "socket=/tmp/uwsgi.sock" >> $file_uri
    echo "plugin=python" >> $file_uri
    echo "processes=$num_cores" >> $file_uri
    echo "pidfile=$script_dir/uwsgi.pid" >> $file_uri
    echo "chdir=$nmis_dir" >> $file_uri
    echo "virtualenv=$nmis_dir/.nmis_virtualenv" >> $file_uri
    echo "module=main" >> $file_uri
    echo "daemonize = $script_dir/uwsgi.log" >> $file_uri
    echo "callable=app" >> $file_uri

    echo "done"
}

write_nginx_config() {
    # in the save vein with write_uwsgi,
    # since the static file needs to be defined dynamically

    script_uri=$(readlink -f $0)
    script_dir=$(dirname $script_uri)
    nmis_dir=$(dirname $script_dir)
    file_name="nmis.nginx"
    file_uri=$script_dir/$file_name

    if [ -f $file_uri ]; then
        echo -n "Overwriting $file_name..."
    else
        echo -n "Creating $file_name..."
    fi

    echo "server {" > $file_uri
    echo "	listen 80;" >> $file_uri
    echo "        server_name localhost;" >> $file_uri
    echo "        charset     utf-8;" >> $file_uri
    echo "" >> $file_uri
    echo "	location ^~ /static/ {" >> $file_uri
    echo "		root $nmis_dir/;" >> $file_uri
    echo "		if (\$query_string) {" >> $file_uri
    echo "			expires max;" >> $file_uri
    echo "		}" >> $file_uri
    echo "	}" >> $file_uri
    echo "	location / {" >> $file_uri
    echo "		include uwsgi_params;" >> $file_uri
    echo "		uwsgi_pass unix:/tmp/uwsgi.sock;" >> $file_uri
    echo "	}" >> $file_uri
    echo "}" >> $file_uri

    echo "done"
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
## rewrite nginx config dynamically
## check if nginx is available
write_nginx_config
check_available nginx

sites_available=/etc/nginx/sites-available/nmis
sites_enabled=/etc/nginx/sites-enabled/nmis
sites_enabled_default=/etc/nginx/sites-enabled/default
echo "check if nginx config is set up"
if [ -e $sites_enabled_default ]; then
    echo "removing default from $sites_enabled..."
    sudo rm $sites_enabled_default
    echo "done."
fi

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
    

