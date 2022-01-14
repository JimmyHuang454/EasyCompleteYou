import os
import sys
import json

from ECY_installer.installer import clangd
from ECY_installer.installer import jedi_ls
from ECY_installer.installer import html
from ECY_installer.installer import pyright
from ECY_installer.installer import json  as lsp_json
from ECY_installer.installer import vls

usable_installer = {
    'ECY_engines.cpp.clangd.clangd': clangd.Install(),
    'ECY_engines.html.html': html.Install(),
    'ECY_engines.python.pyright.pyright': pyright.Install(),
    'ECY_engines.html.vls': vls.Install(),
    'ECY_engines.json.json': lsp_json.Install(),
    'ECY_engines.python.jedi_ls.jedi_ls': jedi_ls.Install()
}

from ECY_installer import base

from colorama import init
from termcolor import colored

# determine if application is a script file or frozen exe
if getattr(sys, 'frozen', False):
    BASE_DIR = os.path.dirname(sys.executable)
elif __file__:
    BASE_DIR = os.path.dirname(__file__)

CONFIG_FILE_PATH = BASE_DIR + '/arch_config.json'
CONFIG_INFO = {}
if not os.path.exists(CONFIG_FILE_PATH):
    with open(CONFIG_FILE_PATH, 'w+') as f:
        f.write("{}")
        f.close()
else:
    with open(CONFIG_FILE_PATH, 'r') as f:
        CONFIG_INFO = json.loads(f.read())
        f.close()


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


def Update(server_name, info):
    CONFIG_INFO[server_name] = info
    with open(CONFIG_FILE_PATH, 'w') as f:
        f.write(json.dumps(CONFIG_INFO))
        f.close()


def Install(server_name):
    current_os = GetCurrentOS()
    obj = usable_installer[server_name]
    fuc = current_os
    if hasattr(obj, fuc):
        fuc = getattr(obj, fuc)
        res = fuc({'save_dir': NewArchieve(server_name)})
        Update(server_name, res)
        base.PrintGreen("Finished. Installed ", server_name)


def UnInstall(server_name):
    current_os = GetCurrentOS()
    obj = usable_installer[server_name]
    fuc = "Clean" + current_os
    if hasattr(obj, fuc):
        fuc = getattr(obj, fuc)
        fuc({'save_dir': NewArchieve(server_name)})
        base.PrintGreen("Finished. Uninstalled ", server_name)
