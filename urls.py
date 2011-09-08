from django.conf.urls.defaults import patterns, include, url

# Uncomment the next two lines to enable the admin:
from django.contrib import admin
admin.autodiscover()

from xform_manager import views as xform_manager_views
OPT_GROUP_REGEX = "((?P<group_name>[^/]+)/)?"

from main import views as main_views

from uis_r_us import views as ui
from survey_photos.views import photo_redirect

urlpatterns = patterns('',
    url(r'^~(?P<reqpath>\S*)', ui.dashboard),
    url(r'^$', main_views.index),

    url(r"^%sformList$" % OPT_GROUP_REGEX, xform_manager_views.formList),
    url(r"^%ssubmission$" % OPT_GROUP_REGEX, xform_manager_views.submission),
    url(r'^xform_manager/', include('nmis.xform_manager.urls')),

    url(r'^description/', main_views.site_description),
    url(r'^facilities/', include('facilities.urls')),
    url(r'^facility_variables', ui.variable_data),
    url(r'^lgas/', include('nmis.nga_districts.urls')),
    url(r'^lgas/$', main_views.list_active_lgas),
    url(r'^modes/(?P<mode_data>\S*)$', ui.modes),
    url(r'^mustache/(?P<template_name>\w+)$', ui.mustache_template),
    url(r'^test/map$', ui.test_map),
    url(r'^test/modes$', ui.test_modes),
    url(r'^resources/', include('resources.urls')),
    url(r'^user_management/', include('user_management.urls')),
    url(r'^survey_photos/(?P<size>\S+)/(?P<photo_id>\S+)$', photo_redirect),

    url(r'^accounts/', include('registration.backends.default.urls')),
    url(r'^admin/', include(admin.site.urls)),
    url(r'^admin/doc/', include('django.contrib.admindocs.urls')),
)
