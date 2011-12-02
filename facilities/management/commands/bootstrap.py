from django.core.management.base import BaseCommand
from django.core.management import call_command
#from optparse import make_option
#from facilities.data_loader import DataLoader
from django.conf import settings
from django.contrib.auth.models import User
#from nga_districts.models import LGA

class Command(BaseCommand):
    help = "Get stuff up and running from nothing."

    def handle(self, *args, **kwargs):
        def sync_and_migrate():
            call_command('syncdb', interactive=False)
            call_command('migrate')

        def create_users():
            admin, created = User.objects.get_or_create(
                username="admin",
                email="admin@admin.com",
                is_staff=True,
                is_superuser=True
                )
            admin.set_password("pass")
            admin.save()
            mdg_user, created = User.objects.get_or_create(
                username="mdg",
                email="mdg@example.com",
                is_staff=True,
                is_superuser=True
                )
            mdg_user.set_password("2015")
            mdg_user.save()

            from django.contrib.sites.models import Site
            if Site.objects.count() == 1:
                site = Site.objects.all()[0]
                site.domain = settings.MAIN_SITE_HOSTNAME
                site.name = settings.MAIN_SITE_HOSTNAME
                site.save()

        sync_and_migrate()
        create_users()