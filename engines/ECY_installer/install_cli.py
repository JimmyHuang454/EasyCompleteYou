import os
import sys
import json

from ECY_installer.installer import clangd
from ECY_installer.installer import jedi_ls

# determine if application is a script file or frozen exe
if getattr(sys, 'frozen', False):
    BASE_DIR = os.path.dirname(sys.executable)
elif __file__:
    BASE_DIR = os.path.dirname(__file__)

usable_installer = {'clangd': clangd.Install(), 'jedi_ls': jedi_ls.Install()}


def GetCurrentOS():
    temp = sys.platform
    if temp == 'win32':
        return 'Windows'
    if temp == 'darwin':
        return 'macOS'
    return "Linux"


def NewArchieve(installer_name: str) -> str:
    arch = BASE_DIR + '/ECY_arch/'
    if not os.path.isdir(arch):
        os.mkdir(arch)
    res = arch + installer_name
    if not os.path.isdir(res):
        os.mkdir(res)
    return res


def Install(server_name):
    current_os = GetCurrentOS()
    obj = usable_installer[server_name]
    fuc = current_os
    if getattr(g_args, item) and hasattr(obj, fuc):
        fuc = getattr(obj, fuc)
        fuc({'save_dir': NewArchieve(item)})
        i.append(item)
        print("Finished. Installed %s." % i)


def UnInstall(server_name):
    current_os = GetCurrentOS()
    obj = usable_installer[server_name]
    fuc = "Clean" + current_os
    if getattr(g_args, item) and hasattr(obj, fuc):
        fuc = getattr(obj, fuc)
        fuc({'save_dir': NewArchieve(item)})
        i.append(item)
        print("Finished. Uninstalled %s." % i)
