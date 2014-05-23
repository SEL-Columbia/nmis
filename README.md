NMIS Project v1.0
====================

#### Note: the NMIS project data is currently in a private repo. When it is publically released by the Nigerian Government, it will be contained within this repository.


1. Pull the repo and use ``pip`` to install Flask.

    pip install Flask

2. Follow the instructions in the pipeline folder to generate lga level json. Symlink `pipeline/lgas` to `static/lgas` (`cd static && ln -sf ../pipeline/lgas lgas`).

3. Cd to the "nmis" folder and run the local server

    python main.py

4. In your browser, go to:
    
    http://localhost:5000

