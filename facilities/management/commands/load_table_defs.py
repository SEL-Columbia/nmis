from django.core.management.base import BaseCommand
from django.core.management import call_command
from django.conf import settings
import os
import json
from collections import defaultdict

from display_defs.models import FacilityTable, TableColumn, ColumnCategory, MapLayerDescription
from utils.csv_reader import CsvReader

class Command(BaseCommand):
    help = "Get districts up and running."

    def handle(self, *args, **kwargs):
        path = os.path.join(settings.DATA_DIR_NAME, 'data_configurations.json')
        with open(path) as f:
            self._config = json.load(f)
        def delete_existing_table_defs():
            FacilityTable.objects.all().delete()
            TableColumn.objects.all().delete()
            ColumnCategory.objects.all().delete()
            MapLayerDescription.objects.all().delete()
        delete_existing_table_defs()
        subgroups = {}
        def load_subgroups():
            sgs = list(CsvReader(os.path.join(settings.DATA_DIR_NAME,"table_definitions", "subgroups.csv")).iter_dicts())
            for sg in sgs:
                if 'slug' in sg:
                    subgroups[sg['slug']] = sg['name']
            return subgroups
        load_subgroups()
        def load_table_types(table_types):
            for tt_data in table_types:
                name = tt_data['name']
                slug = tt_data['slug']
                data_source = tt_data['data_source']
                curtable = FacilityTable.objects.create(name=name, slug=slug)
                csv_reader = CsvReader(os.path.join(settings.DATA_DIR_NAME,"table_definitions", data_source))
                display_order = 0
                for input_d in csv_reader.iter_dicts():
                    subs = []
                    if 'subgroups' in input_d:
                        for sg in input_d['subgroups'].split(" "):
                            if sg in subgroups:
                                subs.append({'name': subgroups[sg], 'slug': sg})
                    for sub in subs:
                        curtable.add_column(sub)
                    try:
                        input_d['display_order'] = display_order
                        d = TableColumn.load_row_from_csv(input_d)
                        display_order += 1
                        curtable.add_variable(d)
                    except:
                        print "Error importing table definition for data: %s" % input_d
        load_table_types(self._config['table_definitions'])
        def load_layer_descriptions(ld):
            for layer_file in ld:
                file_name = os.path.join(settings.DATA_DIR_NAME,"map_layers", layer_file['data_source'])
                layer_descriptions = list(CsvReader(file_name).iter_dicts())
                if layer_file['type'] == "layers":
                    for layer in layer_descriptions:
                        MapLayerDescription.objects.get_or_create(**layer)
                elif layer_file['type'] == "legend_data":
                    layers = defaultdict(list)
                    for layer in layer_descriptions:
                        lslug = layer['slug']
                        lstr = ','.join([layer['value'],\
                                        layer['opacity'],\
                                        layer['color']])
                        layers[lslug].append(lstr)
                    for layer_slug, legend_values in layers.items():
                        try:
                            ml = MapLayerDescription.objects.get(slug=layer_slug)
                            ml.legend_data = ';'.join(legend_values)
                            ml.save()
                        except MapLayerDescription.DoesNotExist:
                            continue
        load_layer_descriptions(self._config['map_layers'])
        print FacilityTable.objects.count()

"""


"""