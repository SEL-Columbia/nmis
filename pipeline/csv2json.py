import csv
import itertools
import json
import os
import shutil

NORMALIZED_VALUES = {
    'NA': None,
    'NaN': None,
    'TRUE': True,
    'yes': True,
    'Yes': True,
    'FALSE': False,
    'no': False,
    'No': False
}

CWD = os.getcwd()

def join_cursors(csv_files):
    open_dirs = itertools.imap(lambda x: csv.DictReader(open(x)), csv_files)
    return itertools.chain.from_iterable(open_dirs)

def create_lga_files(data_folder):
    print 'Reading : ' + data_folder
    path = os.path.join(CWD, data_folder)
    dir_ = os.listdir(path)
    
    files = map(lambda f: os.path.join(path, f), filter(lambda x: x.endswith('csv'), dir_))
    lga_files = filter(lambda f: 'LGA' in f, files)
    fac_files = filter(lambda f: 'NMIS' in f, files)

    lgas = {}

    cur = join_cursors(lga_files)
    for row in cur:
        row = clean_vals(row)
        unique_lga = row['unique_lga']
        if unique_lga:
            if unique_lga in lgas:
                lgas[unique_lga] = update(lgas[unique_lga], row)
            else:
                lgas[unique_lga] = update(row, {'facilities':[]})


    cur = join_cursors(fac_files)
    for row in cur:
        row = clean_vals(row)
        unique_lga = row['unique_lga']
        if unique_lga:
            lgas[unique_lga]['facilities'].append(row)

    out_dir = os.path.join(CWD, 'lgas')
    if os.path.exists(out_dir):
         print "Output directory not empty, removing.."
         shutil.rmtree(out_dir)

    os.makedirs(out_dir)
    

    if None in lga:
        del lga[None]
    for lga, doc in lgas.iteritems():
        filename = lga + '.json'
        destination = os.path.join(out_dir, filename)
        with open(destination, 'w') as f:
            f.write(json.dumps(doc, indent=4, ensure_ascii=False))

    zip_download(data_folder, CWD)
   
def update(d, other): d.update(other); return d

def clean(v): 
    try: 
        v = float(v)
    except:
        v = int(v)
    finally:
        return v
        
clean_vals = lambda row: {k:NORMALIZED_VALUES.get(v, clean(v)) for k, v in row.iteritems()}

def zip_download(in_folder, out_dir):
    out_name = 'nmis_data'
    out_file = os.path.join(out_dir, out_name)
    if os.path.exists(out_file + '.zip'):
        print "found existing {file}, removing".format(file=out_file)
        os.remove(out_file + '.zip')
    shutil.make_archive(out_file, 'zip', in_folder)
    print "created zip file {name}".format(name=out_name)

        
if __name__ == '__main__':
    create_lga_files('output_data')