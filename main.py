import json
import os

import flask



app = flask.Flask(__name__)
app.debug = True


def load_json(name):
    cwd = os.path.dirname(os.path.abspath(__file__))
    path = os.path.join(cwd, 'static', 'data')
    file_path = os.path.join(path, name + '.json')
    with open(file_path, 'r') as f:
        data = f.read()
    return data


@app.context_processor
def lgas():
    zones = json.loads(load_json('zones'))
    lgas = [lga
        for state in zones.values()
        for lgas in state.values()
        for lga in lgas.items()]
    lgas.sort(key=lambda x: x[0])
    return {'lgas': lgas}


@app.route('/')
def index():
    return flask.render_template('index.html')


@app.route('/download')
def download():
    return flask.render_template('download.html')


@app.route('/about')
def about():
    return flask.render_template('about.html')


@app.route('/mdgs')
def mdgs():
    mdg_layers = json.loads(load_json('mdg_layers'));
    return flask.render_template('mdgs.html',
            mdg_layers=mdg_layers)
            


@app.route('/explore')
def explore():
    zones = json.loads(load_json('zones'))
    sorted_zones = []
    for zone, states in zones.items():
        sorted_states = []
        for state, lgas in states.items():
            lgas = sorted(lgas.items(), key=lambda x: x[0])
            sorted_states.append((state, lgas))
        sorted_states.sort(key=lambda x: x[0])
        sorted_zones.append((zone, sorted_states))
    sorted_zones.sort(key=lambda x: x[0])

    return flask.render_template('explore.html', 
        zones=json.dumps(sorted_zones),
        load_json=load_json)


@app.errorhandler(404)
def not_found(error):
    return flask.render_template('error.html'), 404


if __name__ == '__main__':
    app.run(host='0.0.0.0')



