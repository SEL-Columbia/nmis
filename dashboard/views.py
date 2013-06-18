from django.shortcuts import render_to_response
from django.http import HttpResponse, HttpResponseBadRequest
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
def serve_data(request, data_path):
    print "the current data_path is %s " % data_path
    #reg_string = r'districts/([a-z_]+)/data/([a-z_]+).(csv|json)'
    reg_string = r'districts/([a-z_]+)/data/(education|health|water).(csv|json)'
    reg_match = re.match(reg_string, data_path)
    if reg_match:
        print "i passed!!!!!"
        state_lga, sector, ext = reg_match.groups()
        print "lga: %s, sector: %s, ext: %s" % (state_lga, sector, ext)
        water_id = settings.BAMBOO_HASH['Water_LGA']['bamboo_id']

        return HttpResponse('hello')
    else:
        print "i failed the reg test :("
        req_filename = os.path.join(settings.PROJECT_ROOT, 'dashboard', 'protected_data', data_path)
        if os.path.exists(req_filename):
            ffdata = ""
            with open(req_filename, 'r') as f:
                ffdata = f.read()
            return HttpResponse(ffdata)
        return HttpResponseBadRequest("Bad request: %s" % data_path)


