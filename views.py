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
    return render_to_response('about2.html',{
                            },
                            context_instance=RequestContext(request))


@login_required
def render_dashboard(request):
    ci = RequestContext(request)
    return render_to_response("dashboard.html", context_instance=ci)


@login_required
def serve_data(request, data_path):
    # TODO: cleanup/refactor this function
    #print "the current data_path is %s " % data_path
    #reg_string = r'districts/([a-z_]+)/data/([a-z_]+).(csv|json)'
    reg_string = r'districts/([a-z_]+)/data/(education|health|water|lga_data).(csv|json)'
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
        if sector == 'lga_data':
            bamboo_id = settings.BAMBOO_HASH['LGA_Data']['bamboo_id']
        print 'bamboo_id = %s' % bamboo_id
        bamboo_ds = Dataset(dataset_id=bamboo_id)
        print 'created dataset, getting data'
        ffdata = bamboo_ds.get_data(query={'unique_lga': state_lga}, format=ext)
        if sector == 'lga_data':
            ffdata = ffdata[0]
            ffdata = {'data': [{'id': str(key), 'value': str(value)}\
                for key, value in ffdata.iteritems()]}
            ffdata = json.dumps(ffdata)
            # TODO: decide if we want to change the format in the UI
            # TODO: figure out how to get source for data points
        response = HttpResponse(ffdata)
        response['Content-type'] = "application/%s" % ext
        print "data is %s and it is %s long" % (type(ffdata), len(ffdata))
        return response
#        bamboo_url = 'http://bamboo.io/datasets/%s?query={"unique_lga":"%s"}&format=%s' %\
#            (bamboo_id, state_lga, ext)
#        print 'the redirect url is %s' % bamboo_url
#        return HttpResponseRedirect(bamboo_url)
    else:
        #print "i failed the reg test :("
        req_filename = os.path.join(settings.PROJECT_ROOT, 'protected_data', data_path)
        if os.path.exists(req_filename):
            ffdata = ""
            with open(req_filename, 'r') as f:
                ffdata = f.read()
            return HttpResponse(ffdata)
        return HttpResponseBadRequest("Bad request: %s" % data_path)

@login_required
def serve_data_with_files(request, data_path):
    req_filename = os.path.join(settings.PROJECT_ROOT, 'protected_data', data_path)
    if os.path.exists(req_filename):
        ffdata = ""
        with open(req_filename, 'r') as f:
            ffdata = f.read()
        return HttpResponse(ffdata)
    return HttpResponseBadRequest("Bad request: %s" % data_path)

@login_required
def serve_pdf(request, pdf_path):
    print "the pdf_path is %s" % pdf_path
    req_filename = os.path.join(settings.PROJECT_ROOT, 'dashboard', 'static', 'gap_sheet', pdf_path)
    if os.path.exists(req_filename):
        ffdata = ""
        with open(req_filename, 'r') as f:
            ffdata = f.read()
        return HttpResponse(content=ffdata, mimetype='application/pdf')
    return HttpResponseBadRequest("Bad request: %s" % pdf_path)

