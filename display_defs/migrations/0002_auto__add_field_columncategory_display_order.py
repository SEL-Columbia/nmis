# encoding: utf-8
import datetime
from south.db import db
from south.v2 import SchemaMigration
from django.db import models

class Migration(SchemaMigration):

    def forwards(self, orm):
        
        # Adding field 'ColumnCategory.display_order'
        db.add_column('display_defs_columncategory', 'display_order', self.gf('django.db.models.fields.PositiveIntegerField')(null=True), keep_default=False)


    def backwards(self, orm):
        
        # Deleting field 'ColumnCategory.display_order'
        db.delete_column('display_defs_columncategory', 'display_order')


    models = {
        'display_defs.columncategory': {
            'Meta': {'object_name': 'ColumnCategory'},
            'display_order': ('django.db.models.fields.PositiveIntegerField', [], {'null': 'True'}),
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
