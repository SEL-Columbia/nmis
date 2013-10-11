from django.conf.urls.defaults import patterns, include, url

# Uncomment the next two lines to enable the admin:
from django.contrib import admin
admin.autodiscover()

#from xform_manager import views as xform_manager_views
#OPT_GROUP_REGEX = "((?P<group_name>[^/]+)/)?"


import views

#from uis_r_us import views as ui
#from survey_photos.views import photo_redirect


urlpatterns = patterns('',
    url(r'^$', views.homepage),
    url(r'^dashboard2', views.dashboard2),
    url(r'^dashboard', views.dashboard),
    url(r'^accounts/', include('registration.backends.default.urls')),
    url(r'^admin/', include(admin.site.urls)),
    url(r'^admin/doc/', include('django.contrib.admindocs.urls')),
    url(r'^home', views.homepage),
    url(r'^download', views.download),
    url(r'^about', views.about),
    url(r'^mdgs', views.mdgs),
    #url(r'^data/(?P<data_path>\S+)$', views.serve_data),
    url(r'^data/(?P<data_path>\S+)$', views.serve_data_with_files),
    url(r'^gap_sheet/(?P<pdf_path>[^/]+)$', views.serve_pdf),
)
