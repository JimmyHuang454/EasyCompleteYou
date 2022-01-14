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
    VIM_EXE = 'vim'
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
    def __init__(self, vim_script, timeout=300):
        self.vim_script = vim_script
        self.timeout = timeout

        self.cmd = '%s -u NONE -i NONE -n -N --cmd "source %s"' % (
            VIM_EXE, vim_script)

        print(self.cmd)
        if IS_NEOVIM and GetCurrentOS() == 'Windows':
            self.pro = subprocess.Popen(self.cmd, shell=True)
        else:
            self.pro = subprocess.Popen(self.cmd,
                                        shell=True,
                                        stdout=subprocess.PIPE,
                                        stderr=subprocess.PIPE,
                                        stdin=subprocess.PIPE)
        threading.Thread(target=self.Test).start()

    def ReadLog(self):
        log_file_path = self.vim_script + '.log'
        ECY_log_file_path = self.vim_script + '.ECY_log'
        output = ''
        if os.path.exists(log_file_path):
            with open(log_file_path, 'r', encoding='utf-8') as f:
                output += f.read()
                f.close()
            os.remove(log_file_path)

        output += '\n------------\n'

        if os.path.exists(ECY_log_file_path):
            with open(ECY_log_file_path, 'r', encoding='utf-8') as f:
                output += f.read()
                f.close()
            os.remove(ECY_log_file_path)
        return output

    def Test(self):
        try:
            self.pro.wait(self.timeout)
        except Exception as e:  # timeout
            print('timeout', e)
            test_case_queue.put({
                'case': self.vim_script,
                'is_ok': False,
                'is_timeout': True,
                'output': self.ReadLog()
            })
            return

        output = self.ReadLog()
        is_ok = False
        if output.find('Failded') == -1 and output != '' and output.find(
                'test ok') != -1:
            is_ok = True
        res = {
            'case': self.vim_script,
            'is_ok': is_ok,
            'output': output,
            'is_timeout': False,
        }
        test_case_queue.put(res)


running_test_cases = {}

for test_case in all_test_case:
    with open(test_case, 'r', encoding='utf-8') as f:
        temp = f.read()
        f.close()
        if temp.find('XXXX') != -1:
            continue
    running_test_cases[test_case] = {'obj': Case(test_case)}

faided_case = []
timeout_case = []
i = 0
while len(running_test_cases) != 0:
    finished_case = test_case_queue.get()
    i += 1
    if not finished_case['is_ok']:
        faided_case.append(finished_case)

    if finished_case['is_timeout']:
        timeout_case.append(finished_case)

    if i == len(running_test_cases):
        break

print('\nTotal: %s, Failded: %s, Timeout: %s.' %
      (i, len(faided_case), len(timeout_case)))

if len(faided_case) != 0:
    print("-" * 10)
    for item in faided_case:
        print(item['case'])
        print('is_ok: ', item['is_ok'])
        print('is_timeout: ', item['is_timeout'])
        print(item['output'])
    quit(100)
