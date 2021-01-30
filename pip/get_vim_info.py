import os
import json

BASE_DIR = os.path.dirname(os.path.abspath(__file__))


def GetVimrcPath(res, is_vim='vim'):
    res = str(bytes(res, encoding='utf-8'), encoding='utf-8')
    start = 0
    vimrc_path = ''
    for item in res:
        if start == 0:
            if item == "\"":
                start = 1
            continue

        if item != "\"":
            vimrc_path = vimrc_path + item
        else:
            break
    viml_path = BASE_DIR + '/get_vim_info.vim'
    if vimrc_path != '':
        os.popen('%s --noplugin -u %s' % (is_vim, viml_path)).read().strip()
        try:
            with open(BASE_DIR + '/const.txt', 'r', encoding='utf-8') as f:
                res = json.loads(f.readline())
        except Exception as e:
            raise e

        for key in res:
            vimrc_path = vimrc_path.replace(key, res[key])
    return vimrc_path


has_vim = False
vimrc = ''
init = ''
has_nvim = False

res = os.popen('vim --version').read()
if res.find('vimrc') != -1:
    has_vim = True
    vimrc = GetVimrcPath(res)

res = os.popen('nvim --version').read()
if res.find('vimrc') != -1:
    has_nvim = True
    init = GetVimrcPath(res)

if has_nvim == False and has_vim == False:
    print(
        "-- Missing 'vim' or 'neovim' in your shell, please install one of them and put their path into your env to let shell can index them."
    )
    quit()

print('---------------------------')
print('Has vim?', has_vim)
print('Has neovim?', has_nvim)

if has_vim:
    print('ECY will modify "%s"' % vimrc)

if has_nvim:
    print('ECY will modify "%s"' % init)
