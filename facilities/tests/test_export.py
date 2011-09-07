from django.test import TestCase
from facilities.facility_builder import FacilityBuilder
from facilities.models import CalculatedVariable, Variable, Facility, Sector, FacilityRecord, FacilityType, LGAIndicator
from nga_districts.models import Zone, State, LGA

class TestExport(TestCase):
    def setUp(self):
        self.power = Variable.objects.create(
            slug='power', data_type='string'
            )
        self.has_water = Variable.objects.create(
            slug='has_water', data_type='boolean'
            )
        self.num_doctors = Variable.objects.create(
            slug='num_doctors', data_type='float'
            )
        self.zone = Zone.objects.create(name='Zone', slug='zone')
        self.state = State.objects.create(name='State', slug='state', zone=self.zone)
        self.lga = LGA.objects.create(name='Local Government Area', slug='lga', state=self.state)
        self.health = Sector.objects.create(name='Health', slug='health')
        self.education = Sector.objects.create(name='Education', slug='education')
        self.water = Sector.objects.create(name='Water', slug='water')
        self.facility_type = FacilityType.add_root(name='Test', slug='test')
        self.health_facility_1 = Facility.objects.create(facility_id='hf1', lga=self.lga, sector=self.health, facility_type=self.facility_type)
        self.health_facility_1.set(self.power, 'nuclear')
        self.health_facility_1.set(self.has_water, True)
        self.health_facility_1.set(self.num_doctors, 2)
        self.health_facility_2 = Facility.objects.create(facility_id='hf2', lga=self.lga, sector=self.health, facility_type=self.facility_type)
        self.health_facility_2.set(self.power, 'solar')
        self.health_facility_2.set(self.has_water, False)
        self.education_facility_1 = Facility.objects.create(facility_id='ef1', lga=self.lga, sector=self.education, facility_type=self.facility_type)
        self.education_facility_1.set(self.power, 'coal')
        self.water_facility_1 = Facility.objects.create(facility_id='wf1', lga=self.lga, sector=self.water, facility_type=self.facility_type)
        self.water_facility_1.set(self.has_water, True)

    def test_facility_export(self):
        pass

    def test_lga_export(self):
        pass
