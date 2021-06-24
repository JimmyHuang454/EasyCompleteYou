import re
from xmlrpc.server import SimpleXMLRPCServer
import threading
import socket


class Operate(object):
    """
    """
    def __init__(self):
        self.engine_name = 'label'
        self.cache_dict = []
        self.cache_string = []
        self.res = []
        for item in range(100000):
            self.res.append(str(item))
        threading.Thread(target=self.StartServer, daemon=True).start()

    def StartServer(self):
        host = '127.0.0.1'  # 获取本地主机名
        port = 2345  # 设置端口
        server = SimpleXMLRPCServer((host, port))
        server.register_function(self._preview, "preview")
        server.register_function(self._get_content, "content")
        server.serve_forever()

    def _get_content(self):
        return self.res

    def _preview(self, line):
        return line

    def OnBufferEnter(self, context):
        self.cache_string = []
        line_text = '\n'.join(context['params']['buffer_content'])
        self.cache_string = list(set(re.findall(r'\w+', line_text)))
        # self.cache_string.extend(items_list)
        self.cache_dict = []
        for item in self.cache_string:
            # the results_format must at least contain the following keys.
            results_format = {
                'abbr': '',
                'word': '',
                'kind': '',
                'menu': '',
                'info': '',
                'user_data': ''
            }
            results_format['abbr'] = item
            results_format['word'] = item
            results_format['kind'] = '[ID]'
            self.cache_dict.append(results_format)
        return None

    def OnCompletion(self, context):
        context['show_list'] = self.cache_dict
        return context

    def OnInsertLeave(self, context):
        self.OnBufferEnter(context)
        return None
