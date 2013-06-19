from django.shortcuts import render_to_response
from django.http import HttpResponse, HttpResponseBadRequest,\
     HttpResponseRedirect
from django.conf import settings
from django.contrib.auth.decorators import login_required
from django.template import RequestContext
import json
import os
import re
from pybamboo.connection import Connection
from pybamboo.dataset import Dataset

@login_required
def render_dashboard(request):
    ci = RequestContext(request)
    return render_to_response("dashboard.html", context_instance=ci)


@login_required
@csrf_exempt
def serve_data(request, data_path):
    print "the current data_path is %s " % data_path
    #reg_string = r'districts/([a-z_]+)/data/([a-z_]+).(csv|json)'
    reg_string = r'districts/([a-z_]+)/data/(education|health|water).(csv|json)'
    reg_match = re.match(reg_string, data_path)
    if reg_match:
        print "i passed!!!!!"
        state_lga, sector, ext = reg_match.groups()
        print "lga: %s, sector: %s, ext: %s" % (state_lga, sector, ext)
        if sector == 'water':
            bamboo_id = settings.BAMBOO_HASH['Water_Facilities']['bamboo_id']
        if sector == 'education':
            bamboo_id = settings.BAMBOO_HASH['Education_Facilities']['bamboo_id']
        if sector == 'health':
            bamboo_id = settings.BAMBOO_HASH['Health_Facilities']['bamboo_id']
        print 'bamboo_id = %s' % bamboo_id
        #d = Dataset(dataset_id = bamboo_id)
        #print 'created dataset, getting data'
        #data = d.get_data(query={unique_lga:lga},format='csv')
        #data = d.get_data(query={'unique_lga':state_lga})
        # ^not sure if this shit works
        #print "data is %s and it is %s long" % (type(data),len(data))
        bamboo_url = 'http://bamboo.io/datasets/%s?query={"unique_lga":"%s"}&format=%s' %\
            (bamboo_id, state_lga, ext)
        print 'the redirect url is %s' % bamboo_url
        return HttpResponseRedirect(bamboo_url)
    else:
        print "i failed the reg test :("
        req_filename = os.path.join(settings.PROJECT_ROOT, 'dashboard', 'protected_data', data_path)
        if os.path.exists(req_filename):
            ffdata = ""
            with open(req_filename, 'r') as f:
                ffdata = f.read()
            return HttpResponse(ffdata)
        return HttpResponseBadRequest("Bad request: %s" % data_path)


