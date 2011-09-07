from django.core.management.base import BaseCommand
from django.core.management import call_command
from django.conf import settings
from facilities.models import Facility
import csv
import os
from optparse import make_option

class Command(BaseCommand):
    help = "Export the lgas/facilities into .csv files."
    sectors = ['health', 'education', 'water']
    export_types = ['facilities', 'lgas']

    option_list = BaseCommand.option_list + (
        make_option("-s", "--sector",
                    dest="sector",
                    default=None,
                    help="Specify the sector to export (only applies when exporting facilities)",
                    action="store"),
        )

    def handle(self, *args, **kwargs):
        # get the export type
        if len(args) == 0:
            print "You must specify the entities you would like to export ('lgas' or 'facilities')"
            return
        elif args[0] not in self.export_types:
            print "You did not specify a valid export type. Valid types are: %s" % self.export_types
            return
        self.export_type = args[0]

        # set sectors for facilties export
        if self.export_type == 'facilities':
            self.sectors_to_load = self.sectors
            if 'sector' in kwargs and kwargs['sector'] in self.sectors:
                self.sectors_to_load = [kwargs['sector']]
            else:
                print "You did not specify a valid sector. Valid sectors are: %s" % self.sectors
                return

        # interpret the rest of the arguments as variables to export
        self.variables_to_export = args[1:]

        # call the appropriate export command
        getattr(self, "export_%s" % self.export_type)()

    def export_lgas(self):
        print "Exporting LGAs"

    def export_facilities(self):
        print "Exporting facilities"
        for sector in self.sectors_to_load:
            self.export_facilities_for_sector(sector)

    def export_facilities_for_sector(self, sector):
        print "Exporting %s facilities" % sector

    def old_code(self):
        for sector, facilities in Facility.export_geocoords().iteritems():
            with open(os.path.join('export', '%s.csv' % sector), 'wb') as _file:
                writer = csv.writer(_file)
                for facility in facilities:
                    writer.writerow([facility['id'], facility['lat'], facility['long']])
