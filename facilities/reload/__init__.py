"""
python manage.py bootstrap
    "Good for getting your local repo up and running. NEVER run in production"
    * creates and syncs database.
    * creates default users

python manage.py load_sectors
    "Get-or-creates sectors by name"
    * [Sector.objects.get_or_create(slug=s.lower(), name=s) for s in ["Agriculture", "Education", "Health"]]

python manage.py load_key_renames
    "Important to have this before loading data from CSVs"

python manage.py load_districts
    "Loads in the districts.json from the data repo"

python manage.py mark_available_lgas
    "Iterates through the CSVs and sets certain LGAs as available"

python manage.py reload_variables
    "FOR PRODUCTION"
    "This takes the site down momentarily for ALL lgas"
    "Runs 'facilities.reload.sitewide.reload_sitewide()'."

python manage.py load_lgas 366 -n
    "FOR PRODUCTION"
    "This takes the site down for ONE LGA AT A TIME"
    "Runs 'facilities.reload.individual_lga.reload_individual_lga(x)' for each argument"

python manage.py load_table_defs
    "This takes the site down momentarily for ALL LGAS"
    "Reloads the table_defs from the data repo"

"""