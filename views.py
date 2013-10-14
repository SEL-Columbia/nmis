import json
import os
import re

from django.shortcuts import render_to_response, render
from django.http import HttpResponse, HttpResponseBadRequest,\
     HttpResponseRedirect
from django.conf import settings
from django.template import RequestContext


def load_json(name):
    cwd = os.path.dirname(os.path.abspath(__file__))
    path = os.path.join(cwd, 'protected_data', 'new_data')
    file_path = os.path.join(path, name + '.json')
    with open(file_path, 'r') as f:
        json = f.read()
    return json


def context_processor(request):
    return {'zones' : load_json('zones')}


def index(request):
    return render_to_response('index.html',
        {}, context_instance=RequestContext(request))


def download(request):
    return render_to_response('data_download.html',
        {}, context_instance=RequestContext(request))


def about(request):
    return render_to_response('about.html',
        {}, context_instance=RequestContext(request))


def dashboard(request):
    return render(request, 'dashboard.html',
        {
            'indicators': load_json('indicators'),
            'lga_overview': load_json('lga_overview'),
            'lga_sectors': load_json('lga_sectors')
        })


