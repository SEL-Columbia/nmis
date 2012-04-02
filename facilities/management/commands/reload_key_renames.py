from django.core.management.base import BaseCommand
#from django.core.management import call_command
from django.conf import settings
import os

from facilities.data_loader import create_objects_from_csv
from facilities.models import KeyRename

class Command(BaseCommand):
    help = "Get key renames up and running."

    def handle(self, *args, **kwargs):
        KeyRename.objects.all().delete()
        key_renames_path = os.path.join(settings.DATA_DIR_NAME, 'variables', 'key_renames.csv')
        create_objects_from_csv(model=KeyRename, path=key_renames_path)
