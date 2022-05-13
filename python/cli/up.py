import os
import sys
import subprocess
import shutil
import time
import zipfile
import gzip
import tarfile

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

############
#  clangd  #
############
for dirs, _, files in os.walk(BASE_DIR + '/clangd'):
    for item in files:
        if item.find('clangd') == -1 or item.find('indexing') != -1:
            continue
        handling_files = dirs + '/' + item
        output_path = BASE_DIR + '/exes/'
        if item.find('linux') != -1:
            output_path += 'ECY_clangd_Linux.zip'
        elif item.find('windows') != -1:
            output_path += 'ECY_clangd_Windows.zip'
        elif item.find('mac') != -1:
            output_path += 'ECY_clangd_macOS.zip'
        else:
            continue
        os.rename(handling_files, output_path)
        print(output_path)

###################
#  rust_analyzer  #
###################
handling_files = BASE_DIR + '/rust_analyzer/rust-analyzer-x86_64-pc-windows-msvc.gz'
output_path = BASE_DIR + '/exes/ECY_RustAnalyzer_Windows.exe.gz'
os.rename(handling_files, output_path)

handling_files = BASE_DIR + '/rust_analyzer/rust-analyzer-x86_64-apple-darwin.gz'
output_path = BASE_DIR + '/exes/ECY_RustAnalyzer_macOS.exe.gz'
os.rename(handling_files, output_path)

handling_files = BASE_DIR + '/rust_analyzer/rust-analyzer-x86_64-unknown-linux-gnu.gz'
output_path = BASE_DIR + '/exes/ECY_RustAnalyzer_Linux.exe.gz'
os.rename(handling_files, output_path)

#########
#  lua  #
#########
for dirs, _, files in os.walk(BASE_DIR + '/lua'):
    for item in files:
        if item.find('lua') == -1:
            continue
        handling_files = dirs + '/' + item
        output_path = BASE_DIR + '/exes/'
        if item.find('linux') != -1 and item.find('x64') != -1:
            output_path += 'ECY_lua_Linux'
        elif item.find('win32') != -1 and item.find('x64') != -1:
            output_path += 'ECY_lua_Windows'
        elif item.find('darwin') != -1 and item.find('x64') != -1:
            output_path += 'ECY_lua_macOS'
        else:
            continue

        if item.endswith('.tar.gz'):
            output_path += '.tar.gz'
        if item.endswith('.zip'):
            output_path += '.zip'
        os.rename(handling_files, output_path)
        print(output_path)


def UnTarGz(file_path: str, output_dir: str) -> str:
    temp = tarfile.open(file_path)
    temp.extractall(output_dir)
    temp.close()


def UnGz(file_name: str) -> str:
    f_name = file_name.replace(".gz", "")
    g_file = gzip.GzipFile(file_name)
    open(f_name, "wb+").write(g_file.read())
    g_file.close()
    return f_name


#######################################################################
#                             upload all                              #
#######################################################################
for dirs, _, files in os.walk(BASE_DIR + '/exes'):
    for item in files:
        temp = item.split('_')
        print(temp)
        server_name = temp[1]
        platform = temp[2].split('.')[0]

        arch = NewArchieve(platform, server_name)

        handling_files = dirs + '/' + item
        output_dir = arch + '/ECY_exe'
        if zipfile.is_zipfile(handling_files):
            zipfile.ZipFile(handling_files).extractall(output_dir)
        elif handling_files.endswith('.tar.gz'):
            UnTarGz(handling_files, output_dir)
        elif handling_files.endswith('.gz'):
            MoveFile(UnGz(handling_files), output_dir)
        else:
            MoveFile(handling_files, output_dir)

        DoCMD('python -m build', cwd=arch)
        DoCMD(
            'python -m twine upload --repository pypi dist/* --config-file "%s"'
            % (arch + '/.pypirc'),
            cwd=arch)
