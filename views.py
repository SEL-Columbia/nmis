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
from pybamboo.connection import Connection
from pybamboo.dataset import Dataset



def homepage(request):
    return render_to_response('homepage.html',{
                            },
                            context_instance=RequestContext(request))


def download(request):
    return render_to_response('data_download.html',{
                            },
                            context_instance=RequestContext(request))


def about(request):
    return render_to_response('about.html',{
                            },
                            context_instance=RequestContext(request))

def mdgs(request):
    def load_json(name):
        cwd = os.path.dirname(os.path.abspath(__file__))
        path = os.path.join(cwd, 'protected_data', 'new_data')
        file_path = os.path.join(path, name + '.json')
        with open(file_path, 'r') as f:
            json = f.read()
        return json
    return render_to_response('mdgs.html',{
                            },
                            context_instance=RequestContext(request))


@login_required
def dashboard(request):
    ci = RequestContext(request)
    return render_to_response("dashboard.html", context_instance=ci)


def dashboard2(request):
    def load_json(name):
        cwd = os.path.dirname(os.path.abspath(__file__))
        path = os.path.join(cwd, 'protected_data', 'new_data')
        file_path = os.path.join(path, name + '.json')
        with open(file_path, 'r') as f:
            json = f.read()
        return json

    return render_to_response('dashboard2.html',
        {
            'zones': load_json('zones'),
            'indicators': load_json('indicators'),
            'lga_overview': load_json('lga_overview'),
            'lga_sectors': load_json('lga_sectors')
        },
        context_instance=RequestContext(request))

@login_required
def serve_data_with_files(request, data_path):
    req_filename = os.path.join(settings.PROJECT_ROOT, 'protected_data', data_path)
    if os.path.exists(req_filename):
        ffdata = ""
        with open(req_filename, 'r') as f:
            ffdata = f.read()
        return HttpResponse(ffdata)
    return HttpResponseBadRequest("Bad request: %s" % data_path)
