import os
import json

gap_json_file = os.path.join(os.path.dirname(__file__), 'gap_analysis.json')
with open(gap_json_file, 'r') as ff:
    _gap_indicators = ff.read()

GAP_INDICATORS = json.loads(_gap_indicators)

def all_gap_indicators():
    return GAP_INDICATORS
