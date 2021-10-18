import subprocess
import sys
import os

BASE_DIR = os.path.abspath(os.path.dirname(__file__))
BASE_DIR = BASE_DIR.replace('\\', '/')


def DoCMD(cmd):
    print('\n\n==', cmd, '\n')
    subprocess.Popen(cmd, cwd=BASE_DIR, shell=True).wait()


def GetCurrentOS():
    temp = sys.platform
    if temp == 'win32':
        return 'Windows'
    if temp == 'cygwin':
        return 'Cygwin'
    if temp == 'darwin':
        return 'Mac'
    return "Linux"


DoCMD("pyinstaller -F -n %s.exe --specpath %s ./cli.py" %
      (GetCurrentOS(), BASE_DIR))

DoCMD(
    "pyinstaller -F -n jedi_%s.exe --specpath %s ./jedi/jedi_language_server/cli.py"
    % (GetCurrentOS(), BASE_DIR))
