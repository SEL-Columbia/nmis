from django.db import models
import json
import re
import datetime


class KeyRename(models.Model):
    data_source = models.CharField(max_length=64)
    old_key = models.CharField(max_length=64)
    new_key = models.CharField(max_length=64)

    class Meta:
        unique_together = (("data_source", "old_key"),)

    @classmethod
    def _get_rename_dictionary(cls, data_source):
        result = {}
        for key_rename in cls.objects.filter(data_source=data_source):
            result[key_rename.old_key] = key_rename.new_key
        return result

    @classmethod
    def rename_keys(cls, d):
        """
        Apply the rename rules saved in the database to the dict
        d. Assumes that the key '_data_source' is in d.
        """
        temp = {}
        if '_data_source' not in d:
            return
        rename_dictionary = cls._get_rename_dictionary(d['_data_source'])
        for k, v in rename_dictionary.items():
            if k in d:
                temp[v] = d[k]
                del d[k]
            else:
                print "rename rule '%s' not used in data source '%s'" % \
                    (k, d['_data_source'])
        # this could overwrite keys that weren't renamed
        d.update(temp)


class Variable(models.Model):
    name = models.CharField(max_length=255)
    slug = models.CharField(max_length=128, primary_key=True)
    data_type = models.CharField(max_length=20)
    description = models.TextField()
    load_order = models.IntegerField(default=0)

    FIELDS = ['name', 'slug', 'data_type', 'description']

    PRIMITIVE_MAP = {
        'float': 'float',
        'boolean': 'boolean',
        'string': 'string',
        'percent': 'float',
        'proportion': 'float'
    }

    # We simplify the approach in django.contrib.contenttype.models to
    # cache variables. We need to think about how to keep the cache in
    # sync with the database. Though generally, we'll be okay being a
    # little loose right now.
    _cache = {}

    @classmethod
    def get(cls, slug):
        if slug not in cls._cache:
            try:
                cls._cache[slug] = cls.objects.get(slug=slug)
            except Variable.DoesNotExist:
                pass
        return cls._cache.get(slug)

    def get_casted_value(self, value):
        """
        Takes a Variable and a value and casts it to the appropriate Variable.data_type.
        """
        def get_float(x):
            return float(x)

        def get_boolean(x):
            if isinstance(x, bool):
                return x
            if isinstance(x, basestring):
                regex = re.compile('(true|t|yes|y|1)', re.IGNORECASE)
                if regex.search(x.strip()) is not None:
                    return True
            if isinstance(x, basestring):
                regex = re.compile('(false|f|no|n|0)', re.IGNORECASE)
                if regex.search(x.strip()) is not None:
                    return False
            raise Exception

        def get_string(x):
            if unicode(x).strip():
                return unicode(x).strip()
            else:
                raise Exception

        cast_function = {
            'float': get_float,
            'boolean': get_boolean,
            'string': get_string,
            'percent': get_float,
            'proportion': get_float,
            }
        if self.data_type not in cast_function:
            raise Exception("The data type casting function was not found. %s" \
                % self.__unicode__())
        try:
            value = cast_function[self.data_type](value)
        except:
            value = None
        return value

    def to_dict(self):
        return dict([(k, getattr(self, k)) for k in self.FIELDS])

    @classmethod
    def get_full_data_dictionary(cls, as_json=True):
        result = dict([(v.slug, v.to_dict()) for v in cls.objects.all()])
        return result if not as_json else json.dumps(result)

    def value_field(self):
        """
        Data for this variable will be stored in a column
        with this name in a DataRecord.
        """
        return self.PRIMITIVE_MAP[self.data_type] + '_value'

    def __unicode__(self):
        return json.dumps(self.to_dict(), indent=4)


def sum_non_null_values(d, keys):
    """
    Helper function for calculated variables.
    """
    # loop through the keys and get the values to sum from d
    # if the key is not in d, add it to d with a value of 0
    operands = [0]
    for key in keys:
        try:
            if d[key] is not None:
                operands.append(d[key])
        except:
            pass
    return sum(operands)


def or_non_null_values(d, formulas):
    """
    Helper function for calculated variables.
    """
    def any_operand(d, operands):
        for op in operands:
            if eval(op):
                return True
        return False
    # check whether each of the formulas evaluates and
    # if so, add it to the list to be or'ed together
    operands = []
    for f in formulas:
        try:
            eval(f)
            operands.append(f)
        except:
            pass
    if not operands:
        raise Exception
    return any_operand(d, operands)

class CalculatedVariable(Variable):
    """
    example formula: d['num_students_total'] / d['num_tchrs_total']

    Right now calculated variables will only be computed in
    FacilityBuilder.create_facility_from_dict
    """
    formula = models.TextField()

    FIELDS = Variable.FIELDS + ['formula']

    def add_calculated_value(self, d):
        value = self.calculate_value(d)
        if value is not None:
            d[self.slug] = value

    def calculate_value(self, d):
        try:
            return eval(self.formula)
        except:
            return None


class PartitionVariable(CalculatedVariable):
    """
    Variable that can allow for different values based on given criteria.
    """
    partition = models.TextField()

    FIELDS = Variable.FIELDS + ['partition']

    @property
    def info(self):
        # _partition is the python version of partition (which is json)
        if not hasattr(self, '_partition'):
            self._partition = json.loads(self.partition)
        return self._partition

    def calculate_value(self, d):
        try:
            for i in self.info:
                if eval(i['criteria']):
                    return eval(i['value'])
        except:
            return None


class DataRecord(models.Model):
    """
    Not sure if we want to use different columns for data types or do
    some django Meta:abstract=True stuff to have different subclasses of DataRecord
    behave differently. For now, this works and is pretty clean.
    """
    float_value = models.FloatField(null=True)
    boolean_value = models.NullBooleanField()
    string_value = models.CharField(null=True, max_length=255)

    TYPES = ['float', 'boolean', 'string']

    variable = models.ForeignKey(Variable)
    date = models.DateField(null=True)
    source = models.CharField(null=True, max_length=255)
    invalid = models.BooleanField(default=False)

    class Meta:
        abstract = True

    def get_value(self):
        return getattr(self, str(self.variable.value_field()))

    def set_value(self, val):
        setattr(self, str(self.variable.value_field()), val)

    value = property(get_value, set_value)

    def date_string(self):
        if self.date is None:
            return "No date"
        else:
            return self.date.strftime("%D")


class DictModel(models.Model):

    class Meta:
        abstract = True

    def set(self, variable, value, date=None, source=None, invalid=False):
        """
        This is used to add a data record of type variable to the instance.
        It returns the casted value for the variable.
        """
        if date is None:
            date = datetime.date.today()
        kwargs = {
            'variable': variable,
            self._data_record_fk: self,
            'date': date,
            'source': source,
            'invalid': invalid,
            }
        potential_value = variable.get_casted_value(value)
        if potential_value is not None:
            d, created = self._data_record_class.objects.get_or_create(**kwargs)
            d.value = potential_value
            d.save()
            return d.value
        else:
            return potential_value

    def get(self, variable):
        return self.get_latest_value_for_variable(variable)

    def add_data_from_dict(self, d, source=None, and_calculate=False, only_for_missing=False, invalid_vars=[]):
        """
        Key value pairs in d that are in the data dictionary will be
        added to the database along with any calculated variables that apply.

        flags:
            and_calculate: whether to add calculated variables from the data
            only_for_missing: whether or not to add if there is a value
        """
        for key, value in d.iteritems():
            variable = Variable.get(key)
            if variable is not None:
                # update the dict with the casted value
                if only_for_missing and self.get(variable):
                        pass
                else:
                    invalid = True if variable.slug in invalid_vars else False
                    v = self.set(variable, value, None, source, invalid)
                    d[key] = v if not invalid else None
        # clean up d by removing None and invalid values before we calculate anything
        d = dict([(key, value) for key, value in d.iteritems() if value is not None])
        if and_calculate:
            self.add_calculated_values(d, source, only_for_missing, invalid_vars)

    def add_calculated_values(self, d, source=None, only_for_missing=False, invalid_vars=[]):
        for cls in [CalculatedVariable, PartitionVariable]:
            for v in cls.objects.all().order_by('load_order'):
                if only_for_missing and self.get(v):
                    pass
                else:
                    v.add_calculated_value(d)
                    if v.slug in d:
                        invalid = True if v.slug in invalid_vars else False
                        self.set(v, d[v.slug], None, source, invalid)

    def _kwargs(self):
        """
        To get all data records associated with a facility or lga we need to
        filter FacilityRecords or LGARecords that link to this facility or
        lga. Awesome doc string!
        """
        return {self._data_record_fk: self}

    def get_all_data(self):
        def non_null_value(t):
            # returns the first non-null value
            for val_k in ['string_value', 'float_value', 'boolean_value']:
                if t[val_k] is not None:
                    return t[val_k]
            return None
        def date_str(date):
            return date.isoformat()
        records = self._data_record_class.objects.filter(**self._kwargs())
        d = {}
        for r in records.values('variable_id', 'string_value', 'float_value', 'boolean_value', 'date'):
            # todo: test to make sure this sorting is correct
            variable_id = r['variable_id']
            if variable_id not in d:
                d[variable_id] = {}
            d[variable_id][date_str(r['date'])] = non_null_value(r)
        return d

    def _filter_data_for_display(self, data, display_options={}):
        DECIMAL_PLACES = 1
        # hack to format for now
        import locale
        locale.setlocale(locale.LC_ALL, '')
        def display_boolean(value, display_options={}):
            if value:
                return 'Yes'
            else:
                return 'No'

        def display_string(value, display_options={}):
            import re
            return ' '.join([x.capitalize() for x in re.findall(r'\w+', value)])

        def display_float(value, display_options={}):
            if value is None: return None
            if display_options:
                decimal_places = display_options.get('decimal_places', DECIMAL_PLACES)
            else:
                decimal_places = DECIMAL_PLACES
            return locale.format("%f", round(value, decimal_places), grouping=True).rstrip('0').rstrip('.')

        def display_percent(value, display_options={}):
            if value is None: return None
            if display_options:
                decimal_places = display_options.get('decimal_places', DECIMAL_PLACES)
            else:
                decimal_places = DECIMAL_PLACES
            return locale.format("%f", round(value * 100, decimal_places), grouping=True).rstrip('0').rstrip('.') + "%"

        display_functions = {
            'boolean': display_boolean,
            'float': display_float,
            'string': display_string,
            'percent': display_percent,
            'proportion': display_float,
        }
        data_dictionary = Variable.get_full_data_dictionary(as_json=False)
        filtered_data = {}
        for slug, value_dict in data.items():
            filtered_data[slug] = {
                'value': display_functions[data_dictionary[slug]['data_type']](value_dict['value'], display_options.get(slug, {})),
                'source': value_dict['source']
                }
        return filtered_data

    def get_latest_data(self, for_display=False, display_options={}):
        if for_display:
            return self._filter_data_for_display(self._get_latest_data(), display_options)
        else:
            return self._get_latest_data()

    def _get_latest_data(self):
        def non_null_value(t):
            # returns the first non-null value
            for val_k in ['string_value', 'float_value', 'boolean_value']:
                if t[val_k] is not None:
                    return t[val_k]
            return None
        kwargs = dict(self._kwargs(), **{'invalid': False})
        records = self._data_record_class.objects.filter(**kwargs)
        d = {}
        for r in records.values('variable_id', 'string_value', 'float_value', 'boolean_value', 'date', 'source'):
            # todo: test to make sure this sorting is correct
            variable_id = r['variable_id']
            if variable_id not in d or d[variable_id][0] < r['date']:
                # updates the dict if it's the first record of its type OR
                # if its date is more recent than the existing record
                d[variable_id] = \
                        (r['date'], non_null_value(r), r['source'])
        modd = {}
        for variable, valtup in d.items():
            #strips out the 'date' which was used to get most recent.
            modd[variable] = {
                'value': valtup[1],
                'source': valtup[2]
            }
        return modd

    def get_latest_value_for_variable(self, variable):
        if isinstance(variable, basestring):
            variable = Variable.get(slug=variable)
        try:
            kwargs = self._kwargs()
            kwargs['variable'] = variable
            record = self._data_record_class.objects.filter(**kwargs).order_by('-date')[0]
        except IndexError:
            return None
        return record.value

    def dates(self):
        """
        Return a list of dates of all observations for this DictModel.
        """
        drs = self._data_record_class.objects.filter(**self._kwargs()).values('date').distinct()
        return [d['date'] for d in drs]
