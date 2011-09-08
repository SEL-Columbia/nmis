from django.core.management.base import BaseCommand
from django.core.management import call_command
from django.conf import settings
from facilities.models import Facility, Variable, Sector
from nga_districts.models import LGA
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

        # interpret the rest of the arguments as variables to export
        # and make sure that they are valid variables in the system
        self.variables_to_export = list(args[1:])
        self.filter_variables_to_export()
        if not self.variables_to_export:
            self.variables_to_export = 'all'

        # call the appropriate export command
        getattr(self, "export_%s" % self.export_type)()

    def filter_variables_to_export(self):
        for variable in self.variables_to_export:
            try:
                Variable.objects.get(slug=variable)
            except Variable.DoesNotExist:
                self.variables_to_export.remove(variable)

    def export_lgas(self):
        self.set_variables_to_export_for_lga()
        with open(os.path.join('export', 'lgas.csv'), 'wb') as _file:
            writer = csv.writer(_file)
            writer.writerow(self.build_lga_header())
            for lga in LGA.objects.filter(data_loaded=True):
                writer.writerow(self.build_lga_row(lga))

    def set_variables_to_export_for_lga(self):
        if self.variables_to_export == 'all':
            self.variables_to_export = LGA.variables()

    def build_lga_header(self):
        return ['lga_id', 'lga_name', 'state_id', 'state_name'] + self.variables_to_export

    def build_lga_row(self, lga):
        latest_data = lga.get_latest_data()
        row = [lga.id, lga.name, lga.state.id, lga.state.name]
        for key in self.variables_to_export:
            try:
                row.append(latest_data[key])
            except KeyError:
               row.append("")
        return ['%s' % element for element in row]

    def export_facilities(self):
        for sector_slug in self.sectors_to_load:
            self.export_facilities_for_sector(Sector.objects.get(slug=sector_slug))

    def export_facilities_for_sector(self, sector):
        self.set_variables_to_export_for_sector(sector)
        with open(os.path.join('export', '%s.csv' % sector.slug), 'wb') as _file:
            writer = csv.writer(_file)
            writer.writerow(self.build_facility_header(sector))
            for facility in sector.facility_set.all():
                writer.writerow(self.build_facility_row(facility))

    def set_variables_to_export_for_sector(self, sector):
        if self.variables_to_export == 'all':
            self.sector_variables_to_export = sector.facility_variables()
        else:
            self.sector_variables_to_export = self.variables_to_export

    def build_facility_header(self, sector):
        return ['facility_id', 'state_id', 'state_name', 'lga_id', 'lga_name'] + self.sector_variables_to_export

    def build_facility_row(self, facility):
        latest_data = facility.get_latest_data()
        row = [facility.id, facility.lga.state.id, facility.lga.state.name, facility.lga.id, facility.lga.name]
        for key in self.sector_variables_to_export:
            try:
                row.append(latest_data[key])
            except KeyError:
               row.append("")
        return ['%s' % element for element in row]
