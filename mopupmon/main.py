import csv
import datetime
import urllib2
import base64
import json
import logging
import os
import sys

import flask

import secrets


CWD = os.path.dirname(os.path.abspath(__file__))
logging.basicConfig(filename='/tmp/mopupmon.log', level=logging.DEBUG)

app = flask.Flask(__name__)
app.debug = True


def get_surveyed_facilities():
    """
    Returns a dict of the facility data grouped by lga.

    {
        "anambra_idemili_north": [{
            "id": "kycs",
            "name": "Odida Primary health Centre",
            ...
        }]
    }
    """
    urls = [
        'https://formhub.org/ossap/forms/health_mopup/api',
        'https://formhub.org/ossap/forms/education_mopup/api',
        'https://formhub.org/ossap/forms/mopup_questionnaire_health_final/api',
        'https://formhub.org/ossap/forms/mopup_questionnaire_education_final/api'
    ]
    facilities = []

    for url in urls:
        logging.debug('fetching:', url)
        request = urllib2.Request(url)
        base64string = base64.encodestring('%s:%s' % (secrets.username, secrets.password)).replace('\n', '')
        request.add_header('Authorization', 'Basic %s' % base64string)   
        response = urllib2.urlopen(request)
        data = response.read()
        facilities += json.loads(data)

    output = {}
    for fac in facilities:
        lga_id = fac.get('lga', None)
        fac_id = fac.get('facility_ID', None)
        if lga_id:
            fac['id'] = fac_id.lower() if fac_id else None
            fac['name'] = fac.get('facility_name', '')
            lga_facilities = output.setdefault(lga_id, [])
            lga_facilities.append(fac)
    return output


def parse_facilities_csv():
    """
    Parses the education and health CSVs and returns the data structure below.

    Returns:
    {
        "imo_oru_west":  [
            {
                "id": "yxrl",
                "name": "AFONORI Primary School"
            },
            ...
        ]
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

        lga = lgas.setdefault(lga_id, [])
        lga.append({
            'id': fac_id,
            'name': fac_name
        })
    return lgas


def build_zones():
    """
    Builds the following structure from NMIS' zones.json.
    
    [
        {
            "name": "Northeast",
            "states": [
                {
                    "name": "Gombe",
                    "lgas": [
                        {
                            "id": "gombe_kwami",
                            "name": "Kwami"
                        }
                    ]
                }
            ]
        }
    ]
    """
    file_path = os.path.join(CWD, 'zones.json')
    with open(file_path, 'r') as f:
        data = json.loads(f.read())

    # Build zones output
    zones = []
    for zone_name, zone_states in data.items():
        zone = {'name': zone_name}
        states = zone['states'] = []

        for state_name, state_lgas in zone_states.items():
            state = {'name': state_name}
            lgas = state['lgas'] = []

            for lga_name, lga_id in state_lgas.items():
                lga = {
                    'id': lga_id,
                    'name': lga_name
                }
                lgas.append(lga)
            states.append(state)
        zones.append(zone)

    # Sort zones, states, and lgas
    for zone in zones:
        for state in zone['states']:
            state['lgas'].sort(key=lambda x: x['name'])
        zone['states'].sort(key=lambda x: x['name'])
    zones.sort(key=lambda x: x['name'])
    return zones


def merge_survey_data(zones, facilities_by_lga, surveyed_facilities):
    """
    Merges the facility data and FormHub data into the zones data.

    Keyword arguments:
    zones -- zones data
    facilities_by_lga -- lga facility data
    surveyed_facilities -- FormHub surveyed facilities data

    Structure of zone data:
    [
        {
            "name": "Northeast",
            "percent_complete": 40
            "states": [
                {
                    "name": "Gombe",
                    "percent_complete": 40
                    "lgas": [
                        # See LGA data structure below
                    ]
                }
            ]
        }
    ]

    Structure of an LGA's data:
    {
        "imo_oru_west": {
            "percent_complete": 40,
            "surveyed": [
                {
                    "id": "yxrl",
                    "name": "AFONORI Primary School"
                }
            ],
            "unsurveyed": [],
            "new_facilities": [],
            "unknown_facilities": []
        }
    }
    """
    for zone in zones:
        zone_surveyed = 0
        zone_unsurveyed = 0

        for state in zone['states']:
            state_surveyed = 0
            state_unsurveyed = 0

            for lga in state['lgas']:
                lga_id = lga['id']

                # Update with survey data
                lga_facilities = facilities_by_lga.get(lga_id, [])
                surveyed = surveyed_facilities.get(lga_id, [])

                # Mark surveyed/unsurveyed facilities
                lga['surveyed'] = []
                lga['unsurveyed'] = []
                for fac in lga_facilities:
                    fac_surveyed = [f for f in surveyed if f['id'] == fac['id']]
                    if fac_surveyed:
                        lga['surveyed'].append(fac)
                    else:
                        lga['unsurveyed'].append(fac)

                # Mark new facilities & facilities with wrong id
                lga['new_facilities'] = []
                lga['unknown_facilities'] = []                
                for fac in surveyed:
                    fac_in_list = [f for f in lga_facilities if f['id'] == fac['id']]
                    if fac.get('new_old', None) == 'yes':
                        lga['new_facilities'].append(fac)
                    elif not fac_in_list:
                        lga['unknown_facilities'].append(fac)

                # Calculate lga percent_complete
                try:
                    lga['percent_complete'] = int(len(lga['surveyed']) / float(len(lga['surveyed']) + len(lga['unsurveyed'])) * 100)
                except:
                    lga['percent_complete'] = 100

                state_surveyed += len(lga['surveyed'])
                state_unsurveyed += len(lga['unsurveyed'])

            try:
                state['percent_complete'] = int(state_surveyed / float(state_surveyed + state_unsurveyed) * 100)
            except:
                state['percent_complete'] = 100
            zone_surveyed += state_surveyed
            zone_unsurveyed += state_unsurveyed

        try:
            zone['percent_complete'] = int(zone_surveyed / float(zone_surveyed + zone_unsurveyed) * 100)
        except:
            zone['percent_complete'] = 100
    return zones


def fetch_zones_data():
    cache_path = os.path.join(CWD, 'cache.json')
    try:
        epoch = os.path.getmtime(cache_path)
        last_updated = datetime.datetime.fromtimestamp(epoch)
        # age in minutes
        age = int((datetime.datetime.now() - last_updated).seconds / 60)
    except OSError:
        # cache file does not exist
        age = 0

    if not age or age > (12 * 60):
        # Update cache every 12 hours
        try:
            surveyed_facilities = get_surveyed_facilities()
            facilities_by_lga = parse_facilities_csv()
            zones = build_zones()
            zones = merge_survey_data(zones, facilities_by_lga, surveyed_facilities)

            with open(cache_path, 'w') as f:
                f.write(json.dumps(zones))
        except:
            # Formhub down
            e = sys.exc_info()[0]
            logging.error(e)

    with open(cache_path, 'r') as f:
        zones = json.loads(f.read())
    return zones, age


@app.route('/')
def index():
    zones, age = fetch_zones_data()
    return flask.render_template('index.html', zones=zones, age=age, len=len)


@app.route('/<unique_lga>')
def lga(unique_lga):
    zones, age = fetch_zones_data()
    lgas = {}
    for zone in zones:
        for state in zone['states']:
            for lga in state['lgas']:
                lgas[lga['id']] = lga
    if unique_lga not in lgas:
        flask.abort(404)
    return flask.render_template('lga.html', lga=lgas[unique_lga], age=age, len=len)



if __name__ == '__main__':
    app.run('0.0.0.0')




