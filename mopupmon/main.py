import csv
import urllib2
import base64
import json
import os

import secrets


CWD = os.path.dirname(os.path.abspath(__file__))



def get_mopup_data():
    url = "https://formhub.org/ossap/forms/mopup_questionnaire_health_final/api?fields=%5B%22lga%22%2C+%22facility_ID%22%5D"

    request = urllib2.Request(url)
    base64string = base64.encodestring('%s:%s' % (secrets.username, secrets.password)).replace('\n', '')
    request.add_header("Authorization", "Basic %s" % base64string)   
    response = urllib2.urlopen(request)
    data = response.read()
    return json.loads(data)

def parse_csv(file):
    print 'Parsing: ' + file.name
    output = []
    reader = csv.reader(file, delimiter=',', quotechar='"')
    headers = [h.strip('"') for h in reader.next()]
    for row in reader:
        value = {}
        for header, col in zip(headers, row):
            value[header.lower()] = col
        output.append(value)
    return output


def load_facilities():
    results = []
    for fname in os.listdir(CWD):
        file_path = os.path.join(CWD, fname)
        if fname.endswith('.csv'):
            with open(file_path, 'rb') as f:
                result = parse_csv(f)
                results += result
    print results
    return results


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

    Structure of an LGA's data:
    {
        'id': 'gombe_kwami',
        'name': 'Kwami',
        'surveyed': ["Saint Andrews", "Government School"],
        'unsurveyed': ["AFONORI Primary School", "FOGUWA Primary School", "MARI Primary School"],
        'percent_complete': 40
    }
    """

    file_path = os.path.join(CWD, 'zones.json')
    with open(file_path, 'r') as f:
        data = json.loads(f.read())
    zones = {}
    for zone_name, zone in data.items():
        zone

    print data


zones()





