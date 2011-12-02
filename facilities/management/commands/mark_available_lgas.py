from django.core.management.base import BaseCommand
from django.conf import settings
import os
import json
from facilities.models import Sector
from nga_districts.models import LGA, LGARecord
from utils.csv_reader import CsvReader

class Command(BaseCommand):
    help = "Create the 3 sectors"

    def handle(self, *args, **kwargs):
        path = os.path.join(settings.DATA_DIR_NAME, 'data_configurations.json')
        with open(path) as f:
            self._config = json.load(f)
        lga_ids = []
        facility_csv_files = [ff['data_source'] for ff in self._config['facility_csvs']]
        #this process takes about 6 seconds...
        for csv_file in facility_csv_files:
            data_dir = os.path.join(settings.DATA_DIR_NAME, 'facility_csvs')
            path = os.path.join(data_dir, csv_file)
            csv_reader = CsvReader(path)
            for d in csv_reader.iter_dicts():
                lga_id = d.get('_lga_id')
                if lga_id is not None and lga_id not in lga_ids:
                    lga_ids.append(lga_id)
        for lga_id in lga_ids:
            try:
                lga = LGA.objects.get(id=lga_id)
                lga.data_available=True
                lga.save()
            except LGA.DoesNotExist, e:
                print "lga not found: %s" % str(lga_id)
            except ValueError, e:
                print "lga not found: %s" % str(lga_id)
        print "%d LGAs have data" % LGA.objects.filter(data_available=True).count()
