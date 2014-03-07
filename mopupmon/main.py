import csv
import urllib2
import base64
import json
import os

import secrets


CWD = os.path.dirname(os.path.abspath(__file__))



def get_mopup_data():
    """
    Returns a set of facility ids that have been surveyed.

    set(["hcho", "nlqf", "xjeh"])
    """
    url = "https://formhub.org/ossap/forms/mopup_questionnaire_health_final/api?fields=%5B%22lga%22%2C+%22facility_ID%22%5D"
    
    request = urllib2.Request(url)
    base64string = base64.encodestring('%s:%s' % (secrets.username, secrets.password)).replace('\n', '')
    request.add_header("Authorization", "Basic %s" % base64string)   
    response = urllib2.urlopen(request)
    facilities = json.loads(response.read())

    return set(f['facility_ID'].lower() for f in facilities if 'facility_ID' in f)


def parse_facilities(surveyed=set()):
    """
    Parses the education and health CSVs and returns the data structure below.

    Keyword arguments:
    surveyed (optional) -- a set of facility ids that have been surveyed

    Returns:
    {
        "imo_oru_west": {
            "surveyed": ["Saint Andrews", "Government School"],
            "unsurveyed": ["AFONORI Primary School", "FOGUWA Primary School", "MARI Primary School"],
            "percent_complete": 40
            ...
        }
    }
    """
    # Parse CSV files
    facilities = []
    for fname in os.listdir(CWD):
        if not fname.endswith('.csv'):
            continue

        file_path = os.path.join(CWD, fname)            
        with open(file_path, 'rb') as f:
            print 'Parsing: ' + f.name

            reader = csv.reader(f, delimiter=',', quotechar='"')
            headers = [h.strip('"') for h in reader.next()]

            for row in reader:
                facility = {}
                for header, col in zip(headers, row):
                    facility[header.lower()] = col
                facilities.append(facility)
    
    # Build output data structure
    lgas = {}
    for fac in facilities:
        lga_id = fac['unique_lga']
        fac_id = fac['uid']
        fac_name = fac['name']

        lga = lgas.setdefault(lga_id, {})
        surveyed = lga.setdefault('surveyed', [])
        unsurveyed = lga.setdefault('unsurveyed', [])

        if fac_id in surveyed:
            surveyed.append(fac_name)
        else:
            unsurveyed.append(fac_name)

        lga['percent_complete'] = int(len(surveyed) / (len(surveyed) + len(unsurveyed)) * 100)
        lga_facs[fac_id] = fac

    return lgas



def combine_data(facilities, surveyed):
    """
    Keyword arguments:
    zones -- zones data

    Structure of an LGA's data:
    {
        "id": "gombe_kwami",
        "name": "Kwami",
        "surveyed": ["Saint Andrews", "Government School"],
        "unsurveyed": ["AFONORI Primary School", "FOGUWA Primary School", "MARI Primary School"],
        "percent_complete": 40
    }
    """


surveyed = get_mopup_data()
lgas = parse_facilities(surveyed)
print lgas

def zones():
    """
    Structure of zones.json:
    [
        {
            # Zone
            'name': 'Northeast',
            'percent_complete': 78
            'states': [
                {
                    # State
                    'name': 'Gombe',
                    'percent_complete': 55,
                    'lgas': [
                        # lga_ids will later be replaced with objects
                        'gombe_kwami', 'gombe_gombe'
                    ]
                }
            ]
        }
    ]
    """

    file_path = os.path.join(CWD, 'zones.json')
    with open(file_path, 'r') as f:
        data = json.loads(f.read())
    zones = {}
    for zone_name, zone in data.items():
        zone

    print data





