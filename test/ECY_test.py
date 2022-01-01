import subprocess
import threading
import os
import sys
import queue
import argparse

parser = argparse.ArgumentParser(
    description='EasyCompleteYou, Easily complete you.')
parser.add_argument('--vim_exe', help='')
parser.add_argument('--is_neovim', help='')
g_args = parser.parse_args()

VIM_EXE = g_args.vim_exe
if g_args.is_neovim == 'false':
    IS_NEOVIM = False
else:
    IS_NEOVIM = True
print('VIM_EXE', VIM_EXE)
print('IS_NEOVIM', IS_NEOVIM)

BASE_DIR = os.path.abspath(os.path.dirname(__file__))
BASE_DIR = BASE_DIR.replace('\\', '/')

if VIM_EXE is None:
    VIM_EXE = 'D:/Vim/vim82/vim'
    # VIM_EXE = 'D:/Neovim/bin/nvim'
    # IS_NEOVIM = True

START_UP_SCRIPT = BASE_DIR + '/startup.vim'

all_test_case = []
for [top, dirs, file] in os.walk(BASE_DIR + '/test_cases'):
    for item in file:
        full_path = os.path.join(top, item)
        full_path = full_path.replace('\\', '/')
        if not full_path.endswith('vim'):
            continue
        all_test_case.append(full_path)

test_case_queue = queue.Queue()


def GetCurrentOS():
    temp = sys.platform
    if temp == 'win32':
        return 'Windows'
    if temp == 'darwin':
        return 'macOS'
    return "Linux"


class Case(object):
    def __init__(self, vim_script, timeout=60):
        self.vim_script = vim_script
        self.timeout = timeout
        if GetCurrentOS() != 'Windows':
            # subprocess.Popen('sudo chmod 750 -R ' +
            #                  os.path.dirname(os.path.dirname(VIM_EXE)),
            #                  shell=True).wait()
            print('chmod.............')
        self.cmd = '%s -u NONE -i NONE -n -N --cmd "source %s"' % (VIM_EXE,
                                                                   vim_script)
        print(self.cmd)
        if IS_NEOVIM and GetCurrentOS() == 'Windows':
            self.pro = subprocess.Popen(self.cmd,
                                        shell=True,
                                        stdout=subprocess.PIPE,
                                        stderr=subprocess.PIPE)
        else:
            self.pro = subprocess.Popen(self.cmd,
                                        shell=True,
                                        stdout=subprocess.PIPE,
                                        stderr=subprocess.PIPE)
        threading.Thread(target=self.Test).start()

    def Test(self):
        try:
            self.pro.wait(self.timeout)
        except Exception as e:  # timeout
            print('timeout', e)
            test_case_queue.put({
                'case': self.vim_script,
                'is_ok': False,
                'is_timeout': True,
                'output': ''
            })
            return

        log_file_path = self.vim_script + '.log'
        output = ''
        if os.path.exists(log_file_path):
            with open(log_file_path, 'r', encoding='utf-8') as f:
                output = f.read()
                f.close()
            os.remove(log_file_path)

        is_ok = False
        if output.find('Failded') == -1 and output != '':
            is_ok = True
        res = {
            'case': self.vim_script,
            'is_ok': is_ok,
            'output': output,
            'is_timeout': False,
        }
        test_case_queue.put(res)
        print(res)


running_test_cases = {}

for test_case in all_test_case:
    running_test_cases[test_case] = {'obj': Case(test_case)}

i = 0
while len(all_test_case) != 0:
    finished_case = test_case_queue.get()
    i += 1
    print(i)
    if not finished_case['is_ok']:
        quit(1)

    if i == len(all_test_case):
        break
