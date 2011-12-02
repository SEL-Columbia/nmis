from django.core.management.base import BaseCommand
from django.core.management import call_command
from django.conf import settings
import os

class Command(BaseCommand):
    help = "Get districts up and running."

    def handle(self, *args, **kwargs):
        districts_json_path = os.path.join(settings.DATA_DIR_NAME, 'districts', 'districts.json')
        if os.path.exists(districts_json_path):
            call_command("loaddata", districts_json_path)
