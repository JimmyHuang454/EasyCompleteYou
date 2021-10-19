from xmlrpc.server import SimpleXMLRPCServer
import xmlrpc.client
import threading
import queue
import base64

from ECY import rpc
from ECY.debug import logger

from pygments import highlight
from pygments.lexers import PythonLexer
from pygments.formatters.terminal256 import Terminal256Formatter

from ECY_engines.all.fzf.engines import buffer_line
from ECY_engines.all.fzf.engines import file_content_rg
from ECY_engines.all.fzf.engines import buffer

global g_context
global event_id
global g_call_queue
g_context = {}
event_id = 0
g_call_queue = queue.Queue()


class Operate(object):
    def __init__(self, engine_name):
        threading.Thread(target=self.Run, daemon=True).start()
        threading.Thread(target=self._Call, daemon=True).start()

        self.fzf_rpc = xmlrpc.client.ServerProxy("http://127.0.0.1:%s/" %
                                                 '4562',
                                                 allow_none=True)

    def StringToBase64(self, s):
        return str(base64.b64encode(s.encode('utf-8')), encoding='utf-8')

    def Run(self):
        self.fzf_port = 4563

        self.HOST = '127.0.0.1'
        self.client = SimpleXMLRPCServer((self.HOST, self.fzf_port),
                                         allow_none=True,
                                         logRequests=False)
        self.client.register_function(self.Call, "callback")
        self.client.register_function(self.Preview, "preview")
        self.client.serve_forever()

    def OpenFZF(self, context):
        # self.fzf_rpc.new(self.New(buffer.DefaultEngine, context))
        self.fzf_rpc.new(self.New(buffer.DefaultEngine, context))
        return context

    def CloseFZF(self, context):
        self.fzf_rpc.close_fzf({})
        return context

    def _handle_preview(self, event):
        event_id = int(event['id'])
        if event_id not in g_context:
            return ""

        obj = g_context[event_id]['obj']
        if not hasattr(obj, 'items'):
            return ""

        index = ''
        for item in event['line']:
            if item == ' ':
                break
            index += item

        index = int(index)

        if len(obj.items) < index or len(obj.items) == 0:
            event['res'] = {}
        else:
            event['res'] = obj.items[index]
        return event

    def _Call(self):
        while True:
            try:
                event = g_call_queue.get()
                self._handler(event)
            except Exception as e:
                logger.exception(e)

    def _handler(self, event):
        callback_name = event['callback_name']
        event_id = int(event['id'])
        if event_id not in g_context:
            return "event_id not in g_context"
        obj = g_context[event_id]['obj']
        if not hasattr(obj, callback_name):
            return "has no " + callback_name
        fuc = getattr(obj, callback_name)
        return fuc(event)

    def Preview(self, event):
        try:
            event = self._handle_preview(event)
            res = self._handler(event)
            if type(res) is not str:
                return "not str"
        except Exception as e:
            logger.exception(e)
            res = str(e)
        res = self.StringToBase64(res)
        return res

    def Call(self, event):
        g_call_queue.put(event)

    def New(self, new_obj, context):
        global event_id
        event_id += 1
        new_obj = new_obj(event_id)
        try:
            context['source'] = new_obj.GetSource(context)
            context['id'] = event_id
            context['engine_name'] = new_obj.engine_name
            if type(context['source']) != list:
                return
            g_context[event_id] = {
                'obj': new_obj,
                'context': context,
                'id': event_id
            }
            return g_context[event_id]
        except Exception as e:
            logger.exception(e)
