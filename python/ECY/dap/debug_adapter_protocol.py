import threading
import subprocess
import queue
import json

CLIENT_CAPABILITY = {
    'adapterID': 1,
    'clientID': 1,
    'clientName': 'ECY',
    'adapterID': 1,
    'locale': '',
    'linesStartAt1': True,
    'columnsStartAt1': True,
    'pathFormat': 'path',
    'supportsVariableType': True,
    'supportsVariablePaging': True,
    'supportsRunInTerminalRequest': True,
    'supportsMemoryReferences': True,
    'supportsProgressReporting': True,
    'supportsInvalidatedEvent': True,
}


class DAP():
    """docstring for DAP"""
    def __init__(self):
        self.seq: int = 0
        self.encoding: str = 'utf-8'
        self.timeout: int = -1  # never timeout

        self.pro = None
        self.server_respon = queue.Queue()
        self.server_reqeust = queue.Queue()
        self.watting_respone = {}

    def StartServer(self, cmd: str):
        self.cmd = cmd
        self.pro = subprocess.Popen(self.cmd,
                                    shell=True,
                                    stdout=subprocess.PIPE,
                                    stderr=subprocess.PIPE,
                                    stdin=subprocess.PIPE)
        threading.Thread(target=self._read_server)
        threading.Thread(target=self._handle_respon)

    def IsServerAlive(self):
        if self.pro is None:
            return False
        if self.pro.poll() is None:
            return True
        return False

    def _handle_respon(self):
        while True:
            msg = self.server_respon.get()
            req_id = msg['request_seq']
            if req_id not in self.watting_respone:
                continue
            self.watting_respone[req_id].put(msg)
            del self.watting_respone[req_id]

    def _read_server(self):
        while self.IsServerAlive():
            msg = self.pro.stdout.readline()
            msg = msg.decode(self.encoding)
            msg = json.loads(msg)
            if msg['type'] == 'response':
                self.server_respon.put(msg)
            elif msg['type'] == 'request':
                self.server_reqeust.put(msg)

    def _base(self, type):
        self.seq += 1
        return {'type': type, 'seq': self.seq}

    def _event(self, event_name: str):
        temp = self._base('event')
        temp['event'] = event_name
        return temp

    def _request(self, command: str, arguments: dict = {}):
        temp = self._base('request')
        temp['command'] = command
        temp['arguments'] = arguments
        res = queue.Queue()
        self.watting_respone[temp['seq']] = res
        return res.get(timeout=self.timeout)

    def initialized(self, adapterID: str):
        CLIENT_CAPABILITY['adapterID'] = adapterID
        return self._request('initialize', CLIENT_CAPABILITY)
