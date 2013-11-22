current_dir=$(pwd)
nmis_available = /etc/nginx/sites_available/nmis
nmis_enabled = /etc/nginx/sites_enabled/nmis
sudo cp $current_dir/nmis.uwsgi $nmis_available
sudo ln -s $nmis_available $nmis_enabled
uwsgi --ini $current_dir/uwsgi.ini
sudo service nginx restart
