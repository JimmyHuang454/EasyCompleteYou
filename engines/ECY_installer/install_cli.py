import os
import sys
import json
import importlib

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


def Update(installer_name, info):
    CONFIG_INFO[installer_name] = info
    with open(CONFIG_FILE_PATH, 'w') as f:
        f.write(json.dumps(CONFIG_INFO))
        f.close()


def Install(installer_name):
    current_os = GetCurrentOS()
    fuc = current_os
    try:
        obj = importlib.import_module(installer_name)
        obj = obj.Install()
    except Exception as e:
        print(e)
        return
    if hasattr(obj, fuc):
        fuc = getattr(obj, fuc)
        res = fuc({'save_dir': NewArchieve(installer_name)})
        Update(installer_name, res)
        base.PrintGreen("Finished. Installed ", installer_name)


def UnInstall(installer_name):
    current_os = GetCurrentOS()
    fuc = "Clean" + current_os
    try:
        obj = importlib.import_module(installer_name)
        obj = obj.Install()
    except Exception as e:
        print(e)
        return
    if hasattr(obj, fuc):
        fuc = getattr(obj, fuc)
        fuc({'save_dir': NewArchieve(installer_name)})
        base.PrintGreen("Finished. Uninstalled ", installer_name)
