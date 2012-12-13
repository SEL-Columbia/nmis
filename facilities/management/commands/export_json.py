import json
import os

from django.core.management.base import BaseCommand

from facilities.models import Facility, Variable, Sector
from facilities.views import facilities_dict_for_site
from nga_districts.models import LGA

class Command(BaseCommand):
    help = "Export the facilities into .json files."


    def handle(self, *args, **kwargs):
        self._export_lgas()

    def _export_lgas(self):
        lgas_to_export = LGA.objects.filter(data_loaded=True, data_available=True)
        print 'Exporting %s LGAs...' % len(lgas_to_export)
        for lga in lgas_to_export:
            self._export_lga(lga)

    def _export_lga(self, lga):
        dir_name = os.path.join('export', 'districts', lga.unique_slug)
        self._mkdir(dir_name)
        print '>>> %s (%s)' % (lga.name, dir_name)
        self._export_facilities(dir_name, lga)
#        self._export_profile_data(dir_name, lga)
#        self._export_summary(dir_name, lga)
#        self._export_summary_sectors(dir_name, lga)

    def _mkdir(self, dir_name):
        if not os.path.exists(dir_name):
            os.makedirs(dir_name)

    def _export_facilities(self, dir_name, lga):
        file_name = os.path.join(dir_name, 'facilities.json')
        with open(file_name, 'wb') as f:
            f.write(json.dumps(facilities_dict_for_site(lga)['facilities']))
