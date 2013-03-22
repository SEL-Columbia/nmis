import json
from optparse import make_option
import os

from django.conf import settings
from django.core.management.base import BaseCommand, CommandError


class Command(BaseCommand):
    help = 'Update the districts.json for specified LGAs.'

    option_list = BaseCommand.option_list + (
        make_option('-d', '--data',
            action='store',
            dest='data',
            default='{}',
        ),
    )

    DISTRICTS_FILE = os.path.join(settings.PROTECTED_DATA_DIR,
        'geo', 'districts.json')

    def usage(self, subcommand):
        return 'manage.py update_districts -d <data> <lgas>'

    def handle(self, *args, **options):
        data = self._parse_data(options.get('data'))
        lgas = self._parse_lgas(args)

        self.stdout.write('Updating districts.json...\n')
        self.stdout.write('  data: %s\n' % data)
        self.stdout.write('  LGAs: %s\n' % lgas)

        self._update_districts(data, lgas)

    def _parse_data(self, data):
        try:
            data = json.loads(data)
            if not type(data) == dict or not data:
                raise ValueError
        except ValueError:
            raise CommandError('Data must be a valid, non-empty JSON dict.')

        return data

    def _parse_lgas(self, args):
        if not len(args) == 1:
            raise CommandError(
                'LGA list must be comma-separated list of integer ids.')

        ids = args[0].split(',')
        lgas = []

        for id in ids:
            try:
                lgas.append(int(id))
            except ValueError:
                raise CommandError('Invalid lga id (%s).' % id)
        if len(lgas) == 0:
            lgas = 'all'

        return lgas

    def _update_districts(self, data, lgas):
        districts = self._read_districts_file()
        new_districts = self._new_districts_dict(districts, data, lgas)
        self._write_districts_file(new_districts)

    def _read_districts_file(self):
        try:
            with open(self.DISTRICTS_FILE) as f:
                districts = json.loads(f.read())
        except IOError:
            raise CommandError('Cannot open file: %s: File does not exist.' %\
                self.DISTRICTS_FILE)
        except ValueError:
            raise CommandError('File: %s is not a valid JSON document.' %\
                self.DISTRICTS_FILE)

        return districts

    def _new_districts_dict(self, districts, data, lgas):
        new_districts = districts
        try:
            for district in new_districts['districts']:
                if lgas == 'all' or district.get('_lga_id') in lgas:
                    district.update(data)
        except KeyError, TypeError:
            raise CommandError('File: %s is not properly formatted.' %\
                self.DISTRICTS_FILE)

        return new_districts

    def _write_districts_file(self, new_districts):
        try:
            with open(self.DISTRICTS_FILE, 'wb') as f:
                f.write(json.dumps(new_districts, indent=4, sort_keys=True))
        except IOError:
            raise CommandError('File: %s is not writable.' %\
                self.DISTRICTS_FILE)
