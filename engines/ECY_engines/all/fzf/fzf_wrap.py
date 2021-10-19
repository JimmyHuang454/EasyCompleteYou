import subprocess
import xmlrpc.client
import threading
import queue
import sys
import json
import io
from xmlrpc.server import SimpleXMLRPCServer


class FzfWrap:
    """
    """
    def __init__(self, executable='fzf'):
        sys.stdin = io.TextIOWrapper(sys.stdin.buffer, encoding='utf-8')
        sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
        sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')
        self.executable = executable
        self.process = None
        self.items = []
        self.origin_item = []
        self.index = 0
        self.is_fzf_running = False
        self.is_rg = None
        self.cwd = None

    def InitValue(self, dicts, key, default_value):
        if key not in dicts:
            dicts[key] = default_value

    def CloseFzf(self):
        if self.process is not None:
            self.process.terminate()

    def WriteToFzf(self, item):
        if not self.is_fzf_running:
            return

        if type(item) is dict:
            if 'abbr' not in item:
                return
            abbr = item['abbr']
            abbr = abbr.replace('\n', ' ')
            if abbr.replace(' ', '') == '':
                return
            self.items.append(item)
        else:
            return
        temp = str(self.index) + ' ' + abbr + '\n'
        self.process.stdin.write(bytes(temp, encoding='utf-8'))
        self.process.stdin.flush()
        self.index += 1

    def Input(self):
        self.items = []
        self.index = 0

        if self.is_rg is not None and type(self.is_rg) is str:
            self.rg = subprocess.Popen(['rg', '--json', self.is_rg],
                                       stdout=subprocess.PIPE,
                                       cwd=self.cwd)

            while self.rg.poll() is None:
                try:
                    if not self.is_fzf_running:
                        self.rg.terminate()
                        return
                    output_line = self.rg.stdout.readline()
                    if output_line == b'':
                        continue

                    output_json = json.loads(output_line)
                    if output_json['type'] != "match":
                        continue
                    data = output_json['data']
                    if 'lines' not in data or 'text' not in data['lines']:
                        continue
                    text = data['lines']['text']
                    item = {'abbr': text, 'data': data, 'cwd': self.cwd}
                    self.WriteToFzf(item)
                except Exception as e:
                    continue
        else:
            for item in self.origin_item:
                if not self.is_fzf_running:
                    return
                self.WriteToFzf(item)

    def RunFzf(self,
               lists,
               preview=False,
               key_bind={},
               multi=False,
               preview_wrap='wrap',
               color='hl:#945596,hl:#945596,hl+:#945596'):

        self.origin_item = lists
        opts = {}

        self.InitValue(opts, '--no-mouse', True)
        self.InitValue(opts, '--print-query', True)
        self.InitValue(opts, '--no-sort', True)

        self.InitValue(opts, '--no-extended', False)
        self.InitValue(opts, '--exact', False)
        self.InitValue(opts, '--with-nth', '2..')

        self.InitValue(opts, '--multi', multi)
        self.InitValue(opts, '--preview-window', preview_wrap)
        self.InitValue(opts, '--color', color)

        if preview != '' and preview is not None and preview is not False:
            self.InitValue(opts, '--preview', preview)
        else:
            self.InitValue(opts, '--preview', False)

        key_bind['enter'] = ''

        temp = []
        for item in key_bind:
            temp.append(item)

        if temp != []:
            self.InitValue(opts, '--expect', ','.join(temp))

        cmd = [self.executable]

        for key in opts:
            value = opts[key]
            if type(value) is bool:
                if value:
                    cmd.append(key)
            else:
                cmd.append(key + '=' + value)

        cmd.append("--bind=ctrl-d:preview-page-down,ctrl-e:preview-page-up")
        self.process = subprocess.Popen(cmd,
                                        stdin=subprocess.PIPE,
                                        stdout=subprocess.PIPE,
                                        cwd=self.cwd,
                                        stderr=None)
        self.is_fzf_running = True
        threading.Thread(target=self.Input, daemon=True).start()
        self.process.wait()
        self.is_fzf_running = False
        try:
            self.process.stdin.close()
        except Exception as e:
            pass

        res = self.process.stdout.readlines()

        if len(res) == 0 or len(res) == 2:
            return {}  # selete nothing

        self.process.stdout.close()
        seleted_item = str(res[len(res) - 1], encoding='utf-8')

        index = ''
        for item in seleted_item:
            if item == ' ':
                break
            index += item

        index = int(index)
        return self.items[index]


global new_queue

new_queue = queue.Queue()


def Blind(event):
    new_queue.put(event)


def CloseFzf(event):
    global fzf
    fzf.CloseFzf()


def Run():
    fzf_port = 4562
    HOST = '127.0.0.1'
    client = SimpleXMLRPCServer((HOST, fzf_port),
                                allow_none=True,
                                logRequests=False)
    client.register_function(Blind, "new")
    client.register_function(CloseFzf, "close_fzf")
    client.serve_forever()


def Call(callback_name, id, res):
    global vim_side_rpc
    try:
        res['callback_name'] = callback_name
        res['id'] = id
        vim_side_rpc.callback(res)
    except Exception as e:
        # print(e)
        pass


global fzf
global IS_DEBUG

IS_DEBUG = False

if __name__ == "__main__":
    fzf = FzfWrap()
    threading.Thread(target=Run, daemon=True).start()

    global vim_side_rpc
    vim_side_rpc = xmlrpc.client.ServerProxy("http://127.0.0.1:%s/" % '4563',
                                             allow_none=True)

    while True:
        event = new_queue.get()
        event_id = event['id']
        context = event['context']

        if 'rg' in context:
            fzf.is_rg = context['rg']
        else:
            fzf.is_rg = None

        if 'cwd' in context:
            fzf.cwd = context['cwd']
        else:
            fzf.cwd = None

        preview_cmd = "python C:/Users/qwer/Desktop/vimrc/myproject/ECY/RPC/EasyCompleteYou2/engines/ECY_engines/all/fzf/preview.py --event_id %s --line {..1}" % (
            event_id)

        res = fzf.RunFzf(context['source'], preview=preview_cmd)
        res = {'res': res}
        Call('Closed', event_id, res)
