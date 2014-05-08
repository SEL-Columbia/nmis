import json
import os
import subprocess

import flask



app = flask.Flask(__name__)
app.debug = True


def load_file(file_name):
    cwd = os.path.dirname(os.path.abspath(__file__))
    path = os.path.join(cwd, 'static', 'explore')
    if flask.request.args.get('baseline', None):
        baseline_path = os.path.join(path, 'baseline', file_name)
        if os.path.exists(baseline_path):
            path = os.path.join(path, 'baseline')
    path = os.path.join(path, file_name)
    with open(path, 'r') as f:
        data = f.read()
    return data


def call_script(script_name):
    cwd = os.path.dirname(os.path.abspath(__file__))
    path = os.path.join(cwd, 'server_config')
    full_path = os.path.join(path, script_name)
    subprocess.call([full_path], shell=True)


@app.route('/')
def index():
    return flask.render_template('index.html')


@app.route('/download')
def download():
    return flask.render_template('download.html')


@app.route('/about')
def about():
    return flask.render_template('about.html')


@app.route('/explore')
def explore():
    # Sort zones for navigation
    zones = json.loads(load_file('zones.json'))
    sorted_zones = []
    for zone, states in zones.items():
        sorted_states = []
        for state, lgas in states.items():
            lgas = sorted(lgas.items(), key=lambda x: x[0])
            sorted_states.append((state, lgas))
        sorted_states.sort(key=lambda x: x[0])
        sorted_zones.append((zone, sorted_states))
    sorted_zones.sort(key=lambda x: x[0])

    # Sort LGAs for search box
    sorted_lgas = [lga
        for state in zones.values()
        for lgas in state.values()
        for lga in lgas.items()]
    sorted_lgas.sort(key=lambda x: x[0])

    baseline = flask.request.args.get('baseline', None)
    #lgas_folder = '/static/lgas_baseline/' if baseline else '/static/lgas/'
    lgas_folder = '/static/lgas/'
    return flask.render_template('explore.html',
        baseline=baseline,
        lgas_folder=lgas_folder,
        zones=json.dumps(sorted_zones),
        sorted_lgas=json.dumps(sorted_lgas),
        indicators=load_file('indicators.json'),
        lga_overview=load_file('lga_overview.json'),
        lga_view=load_file('lga_view.json'),
        facilities_view=load_file('facilities_view.json'),
        gap_sheet_view=load_file('gap_sheet_view.json'))


@app.route('/mdgs')
def mdgs():
    return flask.render_template('mdgs.html', load_file=load_file)

@app.route('/planning')
def planning():
    return flask.render_template('planning.html')


@app.errorhandler(404)
def not_found(error):
    return flask.render_template('error.html'), 404


@app.route('/git_update', methods=['POST'])
def git_update():
    try:
        payload = flask.request.values.getlist('payload')[0]
        ref = json.loads(payload)['ref']
        if ref == 'refs/heads/master':
            call_script('gitpull.sh')
            call_script('restart.sh')
        return "git update script executed", 200
    except:
        return "wrong post request", 404


if __name__ == '__main__':
    app.run()



