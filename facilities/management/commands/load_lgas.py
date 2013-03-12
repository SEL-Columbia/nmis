from django.core.management.base import BaseCommand
from optparse import make_option
#from facilities.data_loader import load_lgas
import os
import subprocess
from nga_districts.models import LGA
from facilities.reload.individual_lga import reload_individual_lga

def _strings_in_list(l):
    #*args list receives a non-string param
    o = []
    for i in l:
        if isinstance(i, (basestring, int, float, long,)):
            o.append(str(i))
    return o

class Command(BaseCommand):
    help = "Load the LGA data from fixtures."

    option_list = BaseCommand.option_list + (
        make_option("--inside-hup-subprocess",
                    dest="_hup_subprocess",
                    default=False,
                    action="store_true"),
        make_option("-n", "--no-spawn",
                    dest="no_spawn_process",
                    default=False,
                    action="store_true"),
        make_option('-s', '--skip-calculations',
                    dest='skip_calculations',
                    default=False,
                    action='store_true')
    )

    def handle(self, *args, **kwargs):
        if len(args) == 0:
            args = ('all', )
        args = _strings_in_list(args)
        if args[0] == "all":
            args = [l['id'] for l in LGA.objects.all().values('id')]
        if not kwargs['no_spawn_process']:
            if not kwargs['_hup_subprocess']:
                self.start_subprocess(*args, skip_calculations=kwargs['skip_calculations'])
            else:
                self.handle_in_subprocess(*args, skip_calculations=kwargs['skip_calculations'])
        else:
            for lga_id in _strings_in_list(args):
                lga = LGA.objects.get(id=lga_id)
                reload_individual_lga(lga, skip_calculations=kwargs['skip_calculations'])
    
    def start_subprocess(*args, **kwargs):
        hup_args = ["nohup", "python", "manage.py", "load_lgas", "--inside-hup-subprocess"] + _strings_in_list(args)
        if kwargs.get('skip_calculations'):
            hup_args.append('-s')
        if os.path.exists('nohup.out'):
            raise Exception("nohup.out exists. Is the load already running?")
        if os.path.exists('load_script.pid'):
            with open('load_script.pid', 'r') as f:
                pid = f.read()
            raise Exception("load_script.pid exists. Is the process still running? [PID:%s]" % pid)
        pid = subprocess.Popen(hup_args).pid
        with open('load_script.pid', 'w') as f:
            f.write(str(pid))

    def handle_in_subprocess(*args, **kwargs):
        skip_calculations = kwargs.get('skip_calculations', False)
        lgas = [LGA.objects.get(id=lid) for lid in _strings_in_list(args)]
        for lga in lgas:
            reload_individual_lga(lga, skip_calculations)
        os.rename('nohup.out', 'load_script.log')
        os.unlink('load_script.pid')
