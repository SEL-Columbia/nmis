# -*- coding: utf-8 -*-
from django.shortcuts import render_to_response
from django.http import HttpResponse, HttpResponseBadRequest,\
     HttpResponseRedirect
from django.conf import settings
from django.contrib.auth.decorators import login_required
from django.template import RequestContext

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
