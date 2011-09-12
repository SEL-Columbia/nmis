# encoding: utf-8
import datetime
from south.db import db
from south.v2 import SchemaMigration
from django.db import models

class Migration(SchemaMigration):

    def forwards(self, orm):
        
        # Adding model 'Zone'
        db.create_table('nga_districts_zone', (
            ('id', self.gf('django.db.models.fields.AutoField')(primary_key=True)),
            ('name', self.gf('django.db.models.fields.TextField')()),
            ('slug', self.gf('django.db.models.fields.SlugField')(max_length=50, db_index=True)),
        ))
        db.send_create_signal('nga_districts', ['Zone'])

        # Adding model 'State'
        db.create_table('nga_districts_state', (
            ('id', self.gf('django.db.models.fields.AutoField')(primary_key=True)),
            ('name', self.gf('django.db.models.fields.TextField')()),
            ('slug', self.gf('django.db.models.fields.SlugField')(max_length=50, db_index=True)),
            ('zone', self.gf('django.db.models.fields.related.ForeignKey')(related_name='states', to=orm['nga_districts.Zone'])),
        ))
        db.send_create_signal('nga_districts', ['State'])

        # Adding model 'LGARecord'
        db.create_table('nga_districts_lgarecord', (
            ('id', self.gf('django.db.models.fields.AutoField')(primary_key=True)),
            ('float_value', self.gf('django.db.models.fields.FloatField')(null=True)),
            ('boolean_value', self.gf('django.db.models.fields.NullBooleanField')(null=True, blank=True)),
            ('string_value', self.gf('django.db.models.fields.CharField')(max_length=255, null=True)),
            ('variable', self.gf('django.db.models.fields.related.ForeignKey')(to=orm['facilities.Variable'])),
            ('date', self.gf('django.db.models.fields.DateField')(null=True)),
            ('lga', self.gf('django.db.models.fields.related.ForeignKey')(related_name='data_records', to=orm['nga_districts.LGA'])),
        ))
        db.send_create_signal('nga_districts', ['LGARecord'])

        # Adding model 'LGA'
        db.create_table('nga_districts_lga', (
            ('id', self.gf('django.db.models.fields.AutoField')(primary_key=True)),
            ('name', self.gf('django.db.models.fields.TextField')()),
            ('slug', self.gf('django.db.models.fields.SlugField')(max_length=50, db_index=True)),
            ('state', self.gf('django.db.models.fields.related.ForeignKey')(related_name='lgas', to=orm['nga_districts.State'])),
            ('scale_up', self.gf('django.db.models.fields.BooleanField')(default=False)),
            ('unique_slug', self.gf('django.db.models.fields.TextField')(null=True)),
            ('afr_id', self.gf('django.db.models.fields.TextField')(null=True)),
            ('kml_id', self.gf('django.db.models.fields.TextField')(null=True)),
            ('latlng_str', self.gf('django.db.models.fields.TextField')(null=True)),
            ('survey_round', self.gf('django.db.models.fields.IntegerField')(default=0)),
            ('included_in_malaria_survey', self.gf('django.db.models.fields.BooleanField')(default=False)),
            ('geoid', self.gf('django.db.models.fields.PositiveIntegerField')(null=True)),
            ('data_available', self.gf('django.db.models.fields.BooleanField')(default=False)),
            ('data_loaded', self.gf('django.db.models.fields.BooleanField')(default=False)),
            ('data_load_in_progress', self.gf('django.db.models.fields.BooleanField')(default=False)),
        ))
        db.send_create_signal('nga_districts', ['LGA'])


    def backwards(self, orm):
        
        # Deleting model 'Zone'
        db.delete_table('nga_districts_zone')

        # Deleting model 'State'
        db.delete_table('nga_districts_state')

        # Deleting model 'LGARecord'
        db.delete_table('nga_districts_lgarecord')

        # Deleting model 'LGA'
        db.delete_table('nga_districts_lga')


    models = {
        'facilities.variable': {
            'Meta': {'object_name': 'Variable'},
            'data_type': ('django.db.models.fields.CharField', [], {'max_length': '20'}),
            'description': ('django.db.models.fields.TextField', [], {}),
            'name': ('django.db.models.fields.CharField', [], {'max_length': '255'}),
            'slug': ('django.db.models.fields.CharField', [], {'max_length': '128', 'primary_key': 'True'})
        },
        'nga_districts.lga': {
            'Meta': {'object_name': 'LGA'},
            'afr_id': ('django.db.models.fields.TextField', [], {'null': 'True'}),
            'data_available': ('django.db.models.fields.BooleanField', [], {'default': 'False'}),
            'data_load_in_progress': ('django.db.models.fields.BooleanField', [], {'default': 'False'}),
            'data_loaded': ('django.db.models.fields.BooleanField', [], {'default': 'False'}),
            'geoid': ('django.db.models.fields.PositiveIntegerField', [], {'null': 'True'}),
            'id': ('django.db.models.fields.AutoField', [], {'primary_key': 'True'}),
            'included_in_malaria_survey': ('django.db.models.fields.BooleanField', [], {'default': 'False'}),
            'kml_id': ('django.db.models.fields.TextField', [], {'null': 'True'}),
            'latlng_str': ('django.db.models.fields.TextField', [], {'null': 'True'}),
            'name': ('django.db.models.fields.TextField', [], {}),
            'scale_up': ('django.db.models.fields.BooleanField', [], {'default': 'False'}),
            'slug': ('django.db.models.fields.SlugField', [], {'max_length': '50', 'db_index': 'True'}),
            'state': ('django.db.models.fields.related.ForeignKey', [], {'related_name': "'lgas'", 'to': "orm['nga_districts.State']"}),
            'survey_round': ('django.db.models.fields.IntegerField', [], {'default': '0'}),
            'unique_slug': ('django.db.models.fields.TextField', [], {'null': 'True'})
        },
        'nga_districts.lgarecord': {
            'Meta': {'object_name': 'LGARecord'},
            'boolean_value': ('django.db.models.fields.NullBooleanField', [], {'null': 'True', 'blank': 'True'}),
            'date': ('django.db.models.fields.DateField', [], {'null': 'True'}),
            'float_value': ('django.db.models.fields.FloatField', [], {'null': 'True'}),
            'id': ('django.db.models.fields.AutoField', [], {'primary_key': 'True'}),
            'lga': ('django.db.models.fields.related.ForeignKey', [], {'related_name': "'data_records'", 'to': "orm['nga_districts.LGA']"}),
            'string_value': ('django.db.models.fields.CharField', [], {'max_length': '255', 'null': 'True'}),
            'variable': ('django.db.models.fields.related.ForeignKey', [], {'to': "orm['facilities.Variable']"})
        },
        'nga_districts.state': {
            'Meta': {'object_name': 'State'},
            'id': ('django.db.models.fields.AutoField', [], {'primary_key': 'True'}),
            'name': ('django.db.models.fields.TextField', [], {}),
            'slug': ('django.db.models.fields.SlugField', [], {'max_length': '50', 'db_index': 'True'}),
            'zone': ('django.db.models.fields.related.ForeignKey', [], {'related_name': "'states'", 'to': "orm['nga_districts.Zone']"})
        },
        'nga_districts.zone': {
            'Meta': {'object_name': 'Zone'},
            'id': ('django.db.models.fields.AutoField', [], {'primary_key': 'True'}),
            'name': ('django.db.models.fields.TextField', [], {}),
            'slug': ('django.db.models.fields.SlugField', [], {'max_length': '50', 'db_index': 'True'})
        }
    }

    complete_apps = ['nga_districts']
