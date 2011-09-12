# encoding: utf-8
import datetime
from south.db import db
from south.v2 import SchemaMigration
from django.db import models

class Migration(SchemaMigration):

    def forwards(self, orm):
        
        # Adding model 'FacilityTable'
        db.create_table('display_defs_facilitytable', (
            ('id', self.gf('django.db.models.fields.AutoField')(primary_key=True)),
            ('name', self.gf('django.db.models.fields.CharField')(max_length=64)),
            ('slug', self.gf('django.db.models.fields.CharField')(max_length=64)),
        ))
        db.send_create_signal('display_defs', ['FacilityTable'])

        # Adding model 'TableColumn'
        db.create_table('display_defs_tablecolumn', (
            ('id', self.gf('django.db.models.fields.AutoField')(primary_key=True)),
            ('name', self.gf('django.db.models.fields.CharField')(max_length=64)),
            ('descriptive_name', self.gf('django.db.models.fields.CharField')(max_length=64)),
            ('slug', self.gf('django.db.models.fields.CharField')(max_length=64)),
            ('description', self.gf('django.db.models.fields.TextField')(null=True)),
            ('lga_description', self.gf('django.db.models.fields.TextField')(null=True)),
            ('clickable', self.gf('django.db.models.fields.BooleanField')(default=False)),
            ('click_action', self.gf('django.db.models.fields.CharField')(max_length=64, null=True)),
            ('subgroups', self.gf('django.db.models.fields.CharField')(max_length=512, null=True)),
            ('variable_id', self.gf('django.db.models.fields.IntegerField')(null=True)),
            ('facility_table', self.gf('django.db.models.fields.related.ForeignKey')(related_name='variables', to=orm['display_defs.FacilityTable'])),
            ('display_style', self.gf('django.db.models.fields.CharField')(max_length=64, null=True)),
            ('calc_action', self.gf('django.db.models.fields.CharField')(max_length=256, null=True)),
            ('calc_columns', self.gf('django.db.models.fields.CharField')(max_length=512, null=True)),
            ('iconify_png_url', self.gf('django.db.models.fields.CharField')(max_length=256, null=True)),
            ('display_order', self.gf('django.db.models.fields.IntegerField')()),
        ))
        db.send_create_signal('display_defs', ['TableColumn'])

        # Adding model 'ColumnCategory'
        db.create_table('display_defs_columncategory', (
            ('id', self.gf('django.db.models.fields.AutoField')(primary_key=True)),
            ('name', self.gf('django.db.models.fields.CharField')(max_length=64)),
            ('slug', self.gf('django.db.models.fields.CharField')(max_length=64)),
            ('table', self.gf('django.db.models.fields.related.ForeignKey')(related_name='subgroups', to=orm['display_defs.FacilityTable'])),
        ))
        db.send_create_signal('display_defs', ['ColumnCategory'])

        # Adding model 'MapLayerDescription'
        db.create_table('display_defs_maplayerdescription', (
            ('id', self.gf('django.db.models.fields.AutoField')(primary_key=True)),
            ('slug', self.gf('django.db.models.fields.CharField')(max_length=128)),
            ('name', self.gf('django.db.models.fields.CharField')(max_length=128)),
            ('mdg', self.gf('django.db.models.fields.IntegerField')(null=True)),
            ('data_source', self.gf('django.db.models.fields.CharField')(max_length=128)),
            ('description', self.gf('django.db.models.fields.TextField')()),
            ('display_order', self.gf('django.db.models.fields.PositiveSmallIntegerField')()),
            ('sector_string', self.gf('django.db.models.fields.CharField')(max_length=64)),
            ('legend_data', self.gf('django.db.models.fields.CharField')(max_length=1024)),
            ('level_key', self.gf('django.db.models.fields.CharField')(max_length=128)),
            ('indicator_key', self.gf('django.db.models.fields.CharField')(max_length=128)),
        ))
        db.send_create_signal('display_defs', ['MapLayerDescription'])


    def backwards(self, orm):
        
        # Deleting model 'FacilityTable'
        db.delete_table('display_defs_facilitytable')

        # Deleting model 'TableColumn'
        db.delete_table('display_defs_tablecolumn')

        # Deleting model 'ColumnCategory'
        db.delete_table('display_defs_columncategory')

        # Deleting model 'MapLayerDescription'
        db.delete_table('display_defs_maplayerdescription')


    models = {
        'display_defs.columncategory': {
            'Meta': {'object_name': 'ColumnCategory'},
            'id': ('django.db.models.fields.AutoField', [], {'primary_key': 'True'}),
            'name': ('django.db.models.fields.CharField', [], {'max_length': '64'}),
            'slug': ('django.db.models.fields.CharField', [], {'max_length': '64'}),
            'table': ('django.db.models.fields.related.ForeignKey', [], {'related_name': "'subgroups'", 'to': "orm['display_defs.FacilityTable']"})
        },
        'display_defs.facilitytable': {
            'Meta': {'object_name': 'FacilityTable'},
            'id': ('django.db.models.fields.AutoField', [], {'primary_key': 'True'}),
            'name': ('django.db.models.fields.CharField', [], {'max_length': '64'}),
            'slug': ('django.db.models.fields.CharField', [], {'max_length': '64'})
        },
        'display_defs.maplayerdescription': {
            'Meta': {'object_name': 'MapLayerDescription'},
            'data_source': ('django.db.models.fields.CharField', [], {'max_length': '128'}),
            'description': ('django.db.models.fields.TextField', [], {}),
            'display_order': ('django.db.models.fields.PositiveSmallIntegerField', [], {}),
            'id': ('django.db.models.fields.AutoField', [], {'primary_key': 'True'}),
            'indicator_key': ('django.db.models.fields.CharField', [], {'max_length': '128'}),
            'legend_data': ('django.db.models.fields.CharField', [], {'max_length': '1024'}),
            'level_key': ('django.db.models.fields.CharField', [], {'max_length': '128'}),
            'mdg': ('django.db.models.fields.IntegerField', [], {'null': 'True'}),
            'name': ('django.db.models.fields.CharField', [], {'max_length': '128'}),
            'sector_string': ('django.db.models.fields.CharField', [], {'max_length': '64'}),
            'slug': ('django.db.models.fields.CharField', [], {'max_length': '128'})
        },
        'display_defs.tablecolumn': {
            'Meta': {'object_name': 'TableColumn'},
            'calc_action': ('django.db.models.fields.CharField', [], {'max_length': '256', 'null': 'True'}),
            'calc_columns': ('django.db.models.fields.CharField', [], {'max_length': '512', 'null': 'True'}),
            'click_action': ('django.db.models.fields.CharField', [], {'max_length': '64', 'null': 'True'}),
            'clickable': ('django.db.models.fields.BooleanField', [], {'default': 'False'}),
            'description': ('django.db.models.fields.TextField', [], {'null': 'True'}),
            'descriptive_name': ('django.db.models.fields.CharField', [], {'max_length': '64'}),
            'display_order': ('django.db.models.fields.IntegerField', [], {}),
            'display_style': ('django.db.models.fields.CharField', [], {'max_length': '64', 'null': 'True'}),
            'facility_table': ('django.db.models.fields.related.ForeignKey', [], {'related_name': "'variables'", 'to': "orm['display_defs.FacilityTable']"}),
            'iconify_png_url': ('django.db.models.fields.CharField', [], {'max_length': '256', 'null': 'True'}),
            'id': ('django.db.models.fields.AutoField', [], {'primary_key': 'True'}),
            'lga_description': ('django.db.models.fields.TextField', [], {'null': 'True'}),
            'name': ('django.db.models.fields.CharField', [], {'max_length': '64'}),
            'slug': ('django.db.models.fields.CharField', [], {'max_length': '64'}),
            'subgroups': ('django.db.models.fields.CharField', [], {'max_length': '512', 'null': 'True'}),
            'variable_id': ('django.db.models.fields.IntegerField', [], {'null': 'True'})
        }
    }

    complete_apps = ['display_defs']
