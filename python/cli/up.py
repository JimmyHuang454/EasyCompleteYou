import os
import sys
import subprocess
import shutil
import time

BASE_DIR = os.path.abspath(os.path.dirname(__file__))
BASE_DIR = BASE_DIR.replace('\\', '/')


def DoCMD(cmd, cwd=None):
    if cwd is None:
        cwd = BASE_DIR
    print('\n\n==', cmd, '\n', flush=True)
    subprocess.Popen(cmd, cwd=cwd, shell=True).wait()


def Version():
    return time.strftime("%Y.%m%d.%H%M%S", time.localtime())


VERSION = Version()


def NewDir(dir_name):
    if not os.path.exists(dir_name):
        os.mkdir(dir_name)


def NewArchieve(platform: str, exe: str) -> str:
    arch_dir = BASE_DIR + '/pypi/ECY_%s_%s_dir' % (platform, exe)
    NewDir(arch_dir)

    arch = arch_dir + '/ECY_%s_%s' % (platform, exe)
    NewDir(arch)

    exe_dir = arch + '/ECY_exe'
    NewDir(exe_dir)

    ##############
    #  MANIFEST  #
    ##############
    with open(BASE_DIR + '/pypi/MANIFEST_template.in', 'r') as f:
        content = f.read()
        f.close()

    with open(arch + '/ECY_exe/__init__.py', 'w') as f:
        f.close()

    with open(arch + '/MANIFEST.in', 'w') as f:
        f.write(content)
        f.close()

    ###########
    #  token  #
    ###########
    with open(BASE_DIR + '/pypirc', 'r') as f:
        content = f.read()
        content = content.format(token=os.environ.get('PYPI'))
        f.close()

    with open(arch + '/.pypirc', 'w') as f:
        f.write(content)
        f.close()

    ###########
    #  setup  #
    ###########
    with open(BASE_DIR + '/pypi/setup_template.py', 'r') as f:
        content = f.read()
        content = content.format(platform=platform, exe=exe, version=VERSION)
        f.close()

    with open(arch + '/setup.py', 'w') as f:
        f.write(content)
        f.close()

    return arch


def MoveFile(file_path, new_file_path):
    shutil.move(file_path, new_file_path)


DoCMD('python -m pip install --upgrade build')
DoCMD('python -m pip install --upgrade twine')

for dirs, _, files in os.walk(BASE_DIR + '/exes'):
    for item in files:
        temp = item.split('_')
        print(temp)
        server_name = temp[1]
        platform = temp[2].split('.')[0]

        print(server_name)
        print(server_name)

        arch = NewArchieve(platform, server_name)
        MoveFile(dirs + '/' + item, arch + '/ECY_exe')

        DoCMD('python -m build', cwd=arch)
        DoCMD(
            'python -m twine upload --repository pypi dist/* --config-file "%s"'
            % (arch + '/.pypirc'),
            cwd=arch)
