from django.test import TestCase
from django.contrib.contenttypes.models import ContentType
from facilities.data_loader import DataLoader
from facilities.models import Sector, FacilityType


class ImportDataTest(TestCase):

    def setUp(self):
        self.data_loader = DataLoader()

    def test_create_sectors(self):
        self.data_loader.create_sectors()
        sectors = dict([(s.slug, s.name) for s in Sector.objects.all()])
        expected_dict = {
            'education': 'Education',
            'health': 'Health',
            'water': 'Water'
            }
        self.assertEquals(sectors, expected_dict)

    def count_all_objects(self):
        result = {}
        for ct in ContentType.objects.all():
            result[ct.natural_key()] = ct.model_class().objects.count()
        return result
