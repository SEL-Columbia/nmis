import json
import os

import flask



app = flask.Flask(__name__)
app.debug = True


def load_file(file_name):
    cwd = os.path.dirname(os.path.abspath(__file__))
    folder = flask.request.args.get('archive', 'data')
    path = os.path.join(cwd, 'static', folder)
    file_path = os.path.join(path, file_name)
    with open(file_path, 'r') as f:
        data = f.read()
    return data


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

    return flask.render_template('explore.html', 
        zones=json.dumps(sorted_zones),
        sorted_lgas=json.dumps(sorted_lgas),
        indicators=load_file('indicators.json'),
        lga_overview=load_file('lga_overview.json'),
        lga_view=load_file('lga_view.json'),
        table_view=load_file('table_view.json'))


@app.route('/mdgs')
def mdgs():
    return flask.render_template('mdgs.html', load_file=load_file)


@app.errorhandler(404)
def not_found(error):
    return flask.render_template('error.html'), 404


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)



