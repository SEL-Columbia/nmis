from django.shortcuts import render_to_response
from django.http import HttpResponse, HttpResponseBadRequest
from django.conf import settings
from django.contrib.auth.decorators import login_required
from django.template import RequestContext
import json
import os

@login_required
def render_dashboard(request):
    ci = RequestContext(request)
    return render_to_response("dashboard.html", context_instance=ci)

@login_required
def serve_data(request, data_path):
    req_filename = os.path.join(settings.PROJECT_ROOT, 'dashboard', 'protected_data', data_path)
    if os.path.exists(req_filename):
        ffdata = ""
        with open(req_filename, 'r') as f:
            ffdata = f.read()
        return HttpResponse(ffdata)
    return HttpResponseBadRequest("Bad request: %s" % data_path)
