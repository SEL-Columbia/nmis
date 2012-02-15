NMIS Project v0.7
====================

1. Checkout this branch

    git checkout feature/dj13

2. Install MySQL. Right now we put MySQL-python in the
requirements.pip file. This makes deployment easier, but means you
have to have MySQL installed on your machine to install the
requirements.

    sudo apt-get install mysql-server mysql-client libmysqlclient-dev

3. Change directory into the folder where you want to make your
virtual environment, and make a new virtualenv with the following
command

    virtualenv --no-site-packages [name-of-new-virtualenv]

Activate the virtual environment

    source [path-to-virtualev-dir]/bin/activate

Change directory into the folder containing this README.rst and
install the requirements

    pip install -r requirements.pip

4. Install dropbox and make a symbolic link to the cleaned csv folder*

    ln -s ~/Dropbox/NMIS\ -\ Nigeria/NMIS\ Data/final_cleaned_data/csv/ data

5. Run a series of management commands

    # sync, migrate db and add default users
    python manage.py bootstrap

    # load sectors
    python manage.py load_sectors

    # load districts
    python manage.py load_districts

    # go through the data repo and mark lgas that have data available
    python manage.py mark_available_lgas

    # load key renames
    python manage.py load_key_renames

    # load in variables
    python manage.py reload_variables

    # load in lga data for all lgas
    python manage.py load_lgas
    # nb: individual lgas can be loaded as well, eg:
    # python manage.py load_lgas 366

    # load table definitions
    python manage.py load_table_defs

* Alternatively, if you have the keys set up you can pull from the nmis_data private repo:

   git clone wsgi@nmis-linode.mvpafrica.org:repositories/nmis_data.git data