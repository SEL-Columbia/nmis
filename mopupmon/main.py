import csv
import datetime
import urllib2
import base64
import json
import os

import flask

import secrets


CWD = os.path.dirname(os.path.abspath(__file__))
CACHE = {
    "last_updated": datetime.datetime.now(),
    "html": None
}

app = flask.Flask(__name__)
app.debug = True


def get_mopup_data():
    """
    Returns a set of facility ids that have been surveyed.

    set(["hcho", "nlqf", "xjeh"])
    """
    url = "https://formhub.org/ossap/forms/mopup_questionnaire_health_final/api?fields=%5B%22lga%22%2C+%22facility_ID%22%5D"
    
    request = urllib2.Request(url)
    base64string = base64.encodestring("%s:%s" % (secrets.username, secrets.password)).replace("\n", "")
    request.add_header("Authorization", "Basic %s" % base64string)   
    response = urllib2.urlopen(request)
    facilities = json.loads(response.read())

    return set(f["facility_ID"].lower() for f in facilities if "facility_ID" in f)


def parse_facilities(surveyed_ids=set()):
    """
    Parses the education and health CSVs and returns the data structure below.

    Keyword arguments:
    surveyed_ids (optional) -- a set of facility ids that have been surveyed

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
        if not fname.endswith(".csv"):
            continue

        file_path = os.path.join(CWD, fname)            
        with open(file_path, "rb") as f:
            print "Parsing: " + f.name

            reader = csv.reader(f, delimiter=",", quotechar='"')
            headers = [h.strip('"') for h in reader.next()]

            for row in reader:
                facility = {}
                for header, col in zip(headers, row):
                    facility[header.lower()] = col
                facilities.append(facility)
    
    # Build output data structure
    lgas = {}
    for fac in facilities:
        lga_id = fac["unique_lga"]
        fac_id = fac["uid"]
        fac_name = fac["name"]

        lga = lgas.setdefault(lga_id, {})
        surveyed = lga.setdefault("surveyed", [])
        unsurveyed = lga.setdefault("unsurveyed", [])

        if fac_id in surveyed_ids:
            surveyed.append(fac_name)
        else:
            unsurveyed.append(fac_name)

        lga["percent_complete"] = int(len(surveyed) / float(len(surveyed) + len(unsurveyed)) * 100)
    return lgas



def merge_survey_data(lgas, zones):
    """
    Merges the facility survey data to the zones data.

    Keyword arguments:
    zones -- zones data
    lgas -- lga facility data

    Structure of an LGA's data:
    {
        "id": "gombe_kwami",
        "name": "Kwami",
        "surveyed": ["Saint Andrews", "Government School"],
        "unsurveyed": ["AFONORI Primary School", "FOGUWA Primary School", "MARI Primary School"],
        "percent_complete": 40
    }
    """
    for zone in zones:
        zone_surveyed = 0
        zone_unsurveyed = 0

        for state in zone["states"]:
            state_surveyed = 0
            state_unsurveyed = 0

            for lga in state["lgas"]:
                lga_id = lga["id"]

                # Set lga defaults
                lga["percent_complete"] = 100
                lga["surveyed"] = []
                lga["unsurveyed"] = []

                if lga_id in lgas:
                    # Update with survey data
                    lga.update(lgas[lga_id])

                state_surveyed += len(lga["surveyed"])
                state_unsurveyed += len(lga["unsurveyed"])

            state["percent_complete"] = int(state_surveyed / float(state_unsurveyed) * 100)
            zone_surveyed += state_surveyed
            zone_unsurveyed += state_unsurveyed

        zone["percent_complete"] = int(zone_surveyed / float(zone_unsurveyed) * 100)
    print json.dumps(zones, indent=4)
    return zones



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
    file_path = os.path.join(CWD, "zones.json")
    with open(file_path, "r") as f:
        data = json.loads(f.read())

    # Build zones output
    zones = []
    for zone_name, zone_states in data.items():
        zone = {"name": zone_name}
        states = zone["states"] = []

        for state_name, state_lgas in zone_states.items():
            state = {"name": state_name}
            lgas = state["lgas"] = []

            for lga_name, lga_id in state_lgas.items():
                lga = {
                    "id": lga_id,
                    "name": lga_name
                }
                lgas.append(lga)
            states.append(state)
        zones.append(zone)

    # Sort zones, states, and lgas
    for zone in zones:
        for state in zone["states"]:
            state["lgas"].sort(key=lambda x: x["name"])
        zone["states"].sort(key=lambda x: x["name"])
    zones.sort(key=lambda x: x["name"])
    return zones



@app.route('/')
def index():
    seconds_since_update = (datetime.datetime.now() - CACHE["last_updated"]).seconds
    if seconds_since_update > 600 or not CACHE["html"]:
        surveyed = get_mopup_data()
        lgas = parse_facilities(surveyed)
        zones = build_zones()
        zones = merge_survey_data(lgas, zones)
        CACHE["html"] = flask.render_template("index.html", zones=zones, len=len)
        CACHE["last_updated"] = datetime.datetime.now()
    return CACHE["html"]




if __name__ == "__main__":
    app.run()


