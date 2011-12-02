from django.core.management.base import BaseCommand
from django.conf import settings
import os
from facilities.models import Sector

class Command(BaseCommand):
    help = "Create the 3 sectors"

    def handle(self, *args, **kwargs):
        sectors = ['Education', 'Health', 'Water']
        for sector in sectors:
            Sector.objects.get_or_create(slug=sector.lower(), name=sector)
