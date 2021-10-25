import os
import sys
import json
import argparse

from ECY_installer.installer import clangd

# determine if application is a script file or frozen exe
if getattr(sys, 'frozen', False):
    BASE_DIR = os.path.dirname(sys.executable)
elif __file__:
    BASE_DIR = os.path.dirname(__file__)

usable_installer = {'clangd': clangd.Install()}

parser = argparse.ArgumentParser(description='EasyCompleteYou, Installer.')
parser.add_argument('--get_installed_info', action='store_true', help='')

for item in usable_installer:
    obj = usable_installer[item]
    parser.add_argument('--%s' % item,
                        action='store_true',
                        help=obj.Readme({}))
g_args = parser.parse_args()


def GetCurrentOS():
    temp = sys.platform
    if temp == 'win32':
        return 'Windows'
    if temp == 'darwin':
        return 'Mac'
    return "Linux"


def NewArchieve(installer_name: str) -> str:
    res = BASE_DIR + '/ECY_arch/' + installer_name
    if not os.path.isdir(res):
        os.mkdir(res)
    return res


if g_args.get_installed_info:
    res = {
        'clangd': {
            'cmd': '',
            'installed_dir': '',
            'version': '10.0',
            'installer_time': ''
        }
    }
    print(json.dumps(res))
else:
    current_os = GetCurrentOS()
    i = []
    for item in usable_installer:
        obj = usable_installer[item]
        if getattr(g_args, item) and hasattr(obj, current_os):
            fuc = getattr(obj, current_os)
            fuc({'save_dir': NewArchieve(item)})
            i.append(item)

    print("Finished. Installed %s." % i)
