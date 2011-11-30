"""
I'd like to have a place that I can test in the generic data repo that the LGA specific data can be reloadable, one LGA at a time.

This script might be obsolete. But, it might also prove useful down the line if we move code out of data_loader

-AD. 11/29/11
"""

from facilities import data_loader

def reload_individual_lga(lga):
    """
    This method will delete all variables in the database (but not any data records)
    
    It will start the reload process.
    
    The site should only be *down* for a minute or two.
    """
    d = data_loader.DataLoader()
    d.load([lga.id])
    lga.data_loaded = True
    lga.save()
