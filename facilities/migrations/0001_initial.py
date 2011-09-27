# encoding: utf-8
import datetime
from south.db import db
from south.v2 import SchemaMigration
from django.db import models

class Migration(SchemaMigration):

    def forwards(self, orm):
        
        # Adding model 'KeyRename'
        db.create_table('facilities_keyrename', (
            ('id', self.gf('django.db.models.fields.AutoField')(primary_key=True)),
            ('data_source', self.gf('django.db.models.fields.CharField')(max_length=64)),
            ('old_key', self.gf('django.db.models.fields.CharField')(max_length=64)),
            ('new_key', self.gf('django.db.models.fields.CharField')(max_length=64)),
        ))
        db.send_create_signal('facilities', ['KeyRename'])

        # Adding unique constraint on 'KeyRename', fields ['data_source', 'old_key']
        db.create_unique('facilities_keyrename', ['data_source', 'old_key'])

        # Adding model 'Variable'
        db.create_table('facilities_variable', (
            ('name', self.gf('django.db.models.fields.CharField')(max_length=255)),
            ('slug', self.gf('django.db.models.fields.CharField')(max_length=128, primary_key=True)),
            ('data_type', self.gf('django.db.models.fields.CharField')(max_length=20)),
            ('description', self.gf('django.db.models.fields.TextField')()),
        ))
        db.send_create_signal('facilities', ['Variable'])

        # Adding model 'CalculatedVariable'
        db.create_table('facilities_calculatedvariable', (
            ('variable_ptr', self.gf('django.db.models.fields.related.OneToOneField')(to=orm['facilities.Variable'], unique=True, primary_key=True)),
            ('formula', self.gf('django.db.models.fields.TextField')()),
        ))
        db.send_create_signal('facilities', ['CalculatedVariable'])

        # Adding model 'PartitionVariable'
        db.create_table('facilities_partitionvariable', (
            ('calculatedvariable_ptr', self.gf('django.db.models.fields.related.OneToOneField')(to=orm['facilities.CalculatedVariable'], unique=True, primary_key=True)),
            ('partition', self.gf('django.db.models.fields.TextField')()),
        ))
        db.send_create_signal('facilities', ['PartitionVariable'])


    def backwards(self, orm):
        
        # Removing unique constraint on 'KeyRename', fields ['data_source', 'old_key']
        db.delete_unique('facilities_keyrename', ['data_source', 'old_key'])

        # Deleting model 'KeyRename'
        db.delete_table('facilities_keyrename')

        # Deleting model 'Variable'
        db.delete_table('facilities_variable')

        # Deleting model 'CalculatedVariable'
        db.delete_table('facilities_calculatedvariable')

        # Deleting model 'PartitionVariable'
        db.delete_table('facilities_partitionvariable')


    models = {
        'facilities.calculatedvariable': {
            'Meta': {'object_name': 'CalculatedVariable', '_ormbases': ['facilities.Variable']},
            'formula': ('django.db.models.fields.TextField', [], {}),
            'variable_ptr': ('django.db.models.fields.related.OneToOneField', [], {'to': "orm['facilities.Variable']", 'unique': 'True', 'primary_key': 'True'})
        },
        'facilities.keyrename': {
            'Meta': {'unique_together': "(('data_source', 'old_key'),)", 'object_name': 'KeyRename'},
            'data_source': ('django.db.models.fields.CharField', [], {'max_length': '64'}),
            'id': ('django.db.models.fields.AutoField', [], {'primary_key': 'True'}),
            'new_key': ('django.db.models.fields.CharField', [], {'max_length': '64'}),
            'old_key': ('django.db.models.fields.CharField', [], {'max_length': '64'})
        },
        'facilities.partitionvariable': {
            'Meta': {'object_name': 'PartitionVariable', '_ormbases': ['facilities.CalculatedVariable']},
            'calculatedvariable_ptr': ('django.db.models.fields.related.OneToOneField', [], {'to': "orm['facilities.CalculatedVariable']", 'unique': 'True', 'primary_key': 'True'}),
            'partition': ('django.db.models.fields.TextField', [], {})
        },
        'facilities.variable': {
            'Meta': {'object_name': 'Variable'},
            'data_type': ('django.db.models.fields.CharField', [], {'max_length': '20'}),
            'description': ('django.db.models.fields.TextField', [], {}),
            'name': ('django.db.models.fields.CharField', [], {'max_length': '255'}),
            'slug': ('django.db.models.fields.CharField', [], {'max_length': '128', 'primary_key': 'True'})
        }
    }

    complete_apps = ['facilities']
