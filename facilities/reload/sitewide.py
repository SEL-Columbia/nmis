"""
I'd like to have a place that I can test in the generic data repo that the sitewide data (e.g. variable definitions)
are "reloadable".

This script might be obsolete. But, it might also prove useful down the line if we move code out of data_loader

-AD. 11/29/11
"""

from facilities import data_loader
from facilities.models import Variable

def reload_sitewide():
    """
    This method will delete all variables in the database (but not any data records)
    
    It will start the reload process.
    
    The site should only be *down* for a minute or two.
    """
    d = data_loader.DataLoader()
    d.load_variables()
