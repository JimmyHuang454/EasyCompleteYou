import os
import sys
import subprocess
import shutil

BASE_DIR = os.path.abspath(os.path.dirname(__file__))
BASE_DIR = BASE_DIR.replace('\\', '/')

def DoCMD(cmd):
    print('\n\n==', cmd, '\n')
    subprocess.Popen(cmd, cwd=BASE_DIR, shell=True).wait()


