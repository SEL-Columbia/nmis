from django.db import models
from django.db.models import Max
from collections import defaultdict
import sys
import json
from treebeard.mp_tree import MP_Node

from nga_districts.models import LGA, LGARecord
from abstract_models import Variable, CalculatedVariable, PartitionVariable, DataRecord, DictModel, KeyRename


class FacilityRecord(DataRecord):
    facility = models.ForeignKey('Facility', related_name='data_records')

    @classmethod
    def counts_by_variable(cls, lga):
        records = cls.objects.filter(facility__lga=lga, invalid=False).values('facility', 'variable', 'float_value', 'boolean_value', 'string_value', 'facility__sector').annotate(Max('date')).distinct()
        def infinite_dict():
            return defaultdict(infinite_dict)
        result = infinite_dict()
        for d in records:
            variable = Variable.get(d['variable'])
            value = variable.value_field()
            if d[value] in result[d['facility__sector']][d['variable']]:
                result[d['facility__sector']][d['variable']][d[value]] += 1
            else:
                result[d['facility__sector']][d['variable']][d[value]] = 1
        return result

    @classmethod
    def counts_of_boolean_variables(cls, lga):
        result = cls.counts_by_variable(lga)
        for sector, d in result.items():
            for k, v in d.items():
                variable = Variable.get(k)
                if variable.data_type != 'boolean':
                    del d[k]
        return result

    @classmethod
    def count_by_lga(cls, variable):
        value = variable.value_field()
        records = cls.objects.filter(variable=variable, invalid=False).values('facility__lga', 'facility', value).annotate(Max('date')).distinct()
        result = defaultdict(dict)
        for d in records:
            try:
                result[d['facility__lga']][d[value]] += 1
            except KeyError:
                result[d['facility__lga']][d[value]] = 1
        return result


class FacilityType(MP_Node):
    slug = models.CharField(max_length=128)
    name = models.CharField(max_length=128)

    node_order_by = ['slug']

    def __unicode__(self):
        return u'%s: %s' % (self.__class__.__name__, self.name)


class Sector(models.Model):
    slug = models.CharField(max_length=128, primary_key=True)
    name = models.CharField(max_length=128)

    def facility_variables(self):
        # this is a hack to get a list of variables for facilities in this sector
        try:
            facility = Facility.objects.filter(sector=self)[0]
            return facility.get_latest_data().keys()
        except:
            return []


class LGAIndicator(Variable):
    """
    Calculate LGA indicator from facility data. For now these are only
    location level aggregations, we're only looking at the latest
    data.
    """
    origin = models.ForeignKey(Variable, related_name='lga_indicators')
    method = models.CharField(max_length=16)  # count_true/false, avg, percentage_true/false, proportion_true/false, sum
    sector = models.ForeignKey(Sector, null=True)

    def count_boolean(self):
        assert self.origin.data_type == 'boolean', 'Assertion failed: %s (%s) is not a boolean' % (self.origin.slug, self.origin.data_type)
        records = FacilityRecord.objects.filter(variable=self.origin, facility__sector=self.sector, invalid=False).values('facility', 'facility__lga', 'boolean_value').annotate(Max('date')).distinct()
        result = dict([(record['facility__lga'], {'true': 0.0, 'false': 0.0, 'true_and_false': 0.0}) for record in records])
        for d in records:
            if d['boolean_value'] == True:
                result[d['facility__lga']]['true'] += 1.0
            elif d['boolean_value'] == False:
                result[d['facility__lga']]['false'] += 1.0
            if d['boolean_value'] == True or d['boolean_value'] == False:
                result[d['facility__lga']]['true_and_false'] += 1.0
        return result

    def count_true(self):
        return dict([(lga, count_dict['true']) for lga, count_dict in self.count_boolean().items()])

    def count_false(self):
        return dict([(lga, count_dict['false']) for lga, count_dict in self.count_boolean().items()])

    def stats(self):
        assert self.origin.data_type in ['float', 'percent', 'proportion'], 'Assertion failed: %s (%s) is not a float' % (self.origin.slug, self.origin.data_type)
        records = FacilityRecord.objects.filter(variable=self.origin, facility__sector=self.sector, invalid=False).values('facility', 'facility__lga', 'float_value').annotate(Max('date')).distinct()
        result = dict([(record['facility__lga'], {'avg': 0.0, 'count': 0.0, 'sum': 0.0}) for record in records])
        for d in records:
            i = result[d['facility__lga']]['count']
            x_i = d['float_value']
            avg_i = result[d['facility__lga']]['avg']
            sum_i = result[d['facility__lga']]['sum']
            if x_i is None: continue
            result[d['facility__lga']]['avg'] = (x_i + i * avg_i) / (i + 1.0)
            result[d['facility__lga']]['sum'] = sum_i + x_i
            result[d['facility__lga']]['count'] += 1.0
        return result

    def avg(self):
        return dict([(lga, stats['avg']) for lga, stats in self.stats().items()])

    def sum(self):
        return dict([(lga, stats['sum']) for lga, stats in self.stats().items()])

    def count(self):
        return dict([(lga, stats['count']) for lga, stats in self.stats().items()])

    def percentage_true(self):
        return dict([(lga, count_dict['true'] / count_dict['true_and_false']) for lga, count_dict in self.count_boolean().items()])

    def percentage_false(self):
        return dict([(lga, count_dict['false'] / count_dict['true_and_false']) for lga, count_dict in self.count_boolean().items()])

    def proportion_true(self):
        return self.percentage_true()

    def proportion_false(self):
        return self.percentage_false()

    def set_lga_values(self, lga_ids='all', source=None):
        """
        self.method is the name of the aggregation method this
        LGAIndicator should use. Grab that method, call it, and save
        the results on the appropriate LGAs.
        """
        aggregation_method = getattr(self, self.method)
        values = aggregation_method()  # self is implied, that's weird
        for lga_id, value in values.iteritems():
            if lga_ids != "all" and str(lga_id) not in lga_ids:
                continue
            lga = LGA.objects.get(id=lga_id)
            lga.set(self, value, source=source, date=None)  # todo: right now we're ignoring date.


class GapVariable(Variable):
    """
    Has the information needed to do a Gap Analysis on a given variable.
    """
    variable = models.ForeignKey(Variable, related_name='gaps_using_actuals')
    target = models.ForeignKey(Variable, related_name='gaps_using_targets')

    def calculate_gap(self):
        """
        Get all the current and target values for the LGAs and calculate the gaps for them.
        """
        current_values = LGARecord.objects.filter(variable=self.variable).values(self.variable.value_field(), 'lga').annotate(Max('date'))
        current = dict([(d['lga'], d[self.variable.value_field()]) for d in current_values])
        target_values = LGARecord.objects.filter(variable=self.target).values(self.target.value_field(), 'lga').annotate(Max('date'))
        target = dict([(d['lga'], d[self.target.value_field()]) for d in target_values])
        return dict([(lga, max(target[lga] - current[lga], 0.0)) for lga in current.keys() if lga in target])

    def set_lga_values(self, lga_ids='all', source=None):
        values = self.calculate_gap()
        for lga_id, value in values.iteritems():
            if lga_ids != "all" and str(lga_id) not in lga_ids:
                continue
            lga = LGA.objects.get(id=lga_id)
            lga.set(self, value, source=source, date=None)  # todo: right now we're ignoring date.


class Facility(DictModel):
    """
    TODO: Figure out what fields should actually be on a facility. I think all
    fields should be stored in data records, with convenience fields stored in
    the facility model as needed.
    """
    # TODO: Why do we need facility_id?
    facility_id = models.CharField(max_length=100, null=True)
    lga = models.ForeignKey(LGA, related_name="facilities", null=True, default=None)
    facility_type = models.ForeignKey(FacilityType, null=True, default=None)
    sector = models.ForeignKey(Sector, null=True, default=None)

    _data_record_class = FacilityRecord
    _data_record_fk = 'facility'

    def get_lat_lon(self):
        lat_lon = self.facility_id.split()[:2]
        if len(lat_lon) == 2:
            return lat_lon
        else:
            return (None, None)

    def get_latest_data(self):
        """
        This is a temporary way to get the facility_type to the page (as if it were a data record).
        """
        result = super(Facility, self).get_latest_data()
        if self.facility_type is not None:
            result['_facility_type'] = self.facility_type.slug
        return result

    @classmethod
    def get_latest_data_by_lga(cls, lga):
        d = defaultdict(dict)
#        records = FacilityRecord.objects.filter(facility__lga=lga).order_by('variable__slug', '-date')
        records = FacilityRecord.objects.filter(facility__lga=lga, invalid=False).order_by('-date')
        for r in records:
            # todo: test to make sure this sorting is correct
#            if r.variable.slug not in d[r.facility.id]:
#                d[r.facility.id][r.variable.slug] = r.value
            if r.variable_id not in d[r.facility_id]:
                d[r.facility_id][r.variable_id] = r.value
        return d

    @classmethod
    def calculate_total_for_lga(self, lga):
        if self.data_type == "string":
            return None
        else:
            records = FacilityRecord.objects.filter(variable=self, facility__lga=lga, invalid=False)
            tot = 0
            for record in records:
                tot += record.value
            return tot

    @classmethod
    def calculate_average_for_lga(self, lga):
        if self.data_type == "string":
            return None
        else:
            records = FacilityRecord.objects.filter(variable=self, facility__lga=lga, invalid=False)
            count = records.count()
            if count == 0:
                return 0
            tot = 0
            for record in records:
                tot += record.value
            return tot / count

    @classmethod
    def export_geocoords(cls):
        # TODO: exception handling!
        facilities = defaultdict(list)
        for f in Facility.objects.all():
            # use facility_id for now (major hack)
            lat, lon = f.facility_id.split()[:2]
            facilities[f.sector.slug].append({
                    'id': f.id,
                    'lat': float(lat),
                    'long': float(lon)
                })
        return facilities

    def save_s3_photo_id(self):
        """
        This will set an "s3_photo_id" which is used to build urls of the image and thumbnails.

        The photos are stored in s3 in 36 different directories (a-z0-9.) This is to prevent the situation
        where all the photos are stored in one directory.

        "123456.jpg" would create an s3_photo_id of "f:123456"
            * In this example, "f" is the first character of the md5sum of the image ID.
            * the image ID is pulled from the filename given by ODK.
            * this ID is used to build URLs for thumbnails and full size images.
        """
        s3_variable, created = Variable.objects.get_or_create(name="S3 Photo ID",
                        slug="s3_photo_id", data_type="string")
        try:
            s3_photo_id_record = FacilityRecord.objects.get(variable=s3_variable, facility=self)
            return s3_photo_id_record.value
        except FacilityRecord.DoesNotExist, e:
            s3_photo_id_record = False

        try:
            photo = FacilityRecord.objects.get(variable="photo", facility=self)
        except FacilityRecord.DoesNotExist, e:
            return None
        import re
        photo_id = re.sub(".jpg", "", photo.value)
        def _get_photo_subdirectory(photo_id):
            import hashlib
            return hashlib.md5(photo_id).hexdigest()[0]
        s3_photo_id = ":".join([_get_photo_subdirectory(photo_id), photo_id])
        self.set(s3_variable, s3_photo_id)
        return s3_photo_id

from xform_manager.models import Instance
from django.db.models.signals import post_save
from facility_builder import FacilityBuilder

def create_facility_from_signal(sender, **kwargs):
    survey_instance = kwargs["instance"]
    try:
        FacilityBuilder.create_facility_from_instance(survey_instance)
    except:
        print "Unexpected error:", sys.exc_info()[0]

post_save.connect(create_facility_from_signal, sender=Instance)
