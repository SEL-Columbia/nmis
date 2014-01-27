#restart uwsgi 
uwsgi --stop uwsgi.pid
uwsgi --ini uwsgi.ini

#restart nginx
sudo service nginx restart
