# -*- coding: utf-8 -*-
from django.shortcuts import render_to_response
from django.http import HttpResponse, HttpResponseBadRequest,\
     HttpResponseRedirect
from django.conf import settings
from django.contrib.auth.decorators import login_required
from django.template import RequestContext
import json
import os
import re

@login_required
def serve_data_with_files(request, data_path):
    req_filename = os.path.join(settings.PROJECT_ROOT, 'dashboard', 'protected_data', data_path)
    if os.path.exists(req_filename):
        ffdata = ""
        with open(req_filename, 'r') as f:
            ffdata = f.read()
        return HttpResponse(ffdata)
    return HttpResponseBadRequest("Bad request: %s" % data_path)


