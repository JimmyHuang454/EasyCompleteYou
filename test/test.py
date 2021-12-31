import subprocess
import os

VIM_EXE = os.environ.get('VIM_EXE')
BASE_DIR = os.path.abspath(os.path.dirname(__file__))
BASE_DIR = BASE_DIR.replace('\\', '/')

if VIM_EXE is None:
    VIM_EXE = 'D:/Vim/vim82/vim'

START_UP_SCRIPT = BASE_DIR + '/startup.vim'

cmd = '%s -u NONE -i NONE -n -N --cmd "source %s"' % (VIM_EXE, START_UP_SCRIPT)

print(cmd)
# subprocess.Popen(cmd).wait()
