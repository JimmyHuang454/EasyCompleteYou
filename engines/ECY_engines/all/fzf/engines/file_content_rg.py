import os

from ECY import rpc
from ECY.debug import logger

try:
    from pygments import highlight
    from pygments.lexers import PythonLexer
    from pygments.formatters.terminal256 import Terminal256Formatter
    global has_pygment
    has_pygment = True
except:
    has_pygment = False


class Operate(object):
    """
    """
    def __init__(self, event_id):
        self.event_id = event_id

        self.items = []
        self.engine_name = 'Rg'

    def GetSource(self, event):
        params = event['params']
        event['rg'] = params['current_word']
        event['cwd'] = params['cwd']
        return []

    def Closed(self, event):
        res = event['res']
        if res != {}:
            pass
        rpc.DoCall('ECho', [str(event)])

    def Preview(self, event):
        res = event['res']
        if res == {}:
            return "none"

        global has_pygment
        if not has_pygment:
            return "missing pygments"

        cwd = res['cwd']
        path = cwd + '/' + res['data']['path']['text']
        if not os.path.exists(path):
            return ""

        with open(path, 'r', encoding='utf-8') as f:
            content = f.read()

        return highlight(content, PythonLexer(), Terminal256Formatter())
