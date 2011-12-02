from django.core.management.base import BaseCommand
from django.core.management import call_command
from django.conf import settings
import os

from facilities.reload.sitewide import reload_sitewide

class Command(BaseCommand):
    help = "Get sitewide data up and running."

    def handle(self, *args, **kwargs):
        reload_sitewide()
