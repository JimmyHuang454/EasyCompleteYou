from ECY import rpc
from ECY import utils
from ECY.debug import logger

from ECY_engines.all.fzf import plugin_base


class DefaultEngine(plugin_base.Plugin):
    """
    """
    def __init__(self, event_id):
        self.event_id = event_id

        self.items = []
        self.engine_name = 'Buffer'

    def RegKeyBind(self):
        return {'ctrl-t': self._open_in_new_tab, 'ctrl-n': ''}

    def _open_in_new_tab(self, event):
        res = event['res']
        if res == {}:
            return
        rpc.DoCall('ClosePopupWindows2')

    def GetSource(self, event):
        params = event['params']

        buffers_list = rpc.DoCall('ECY#utils#GetBufferPath')
        add_list = []
        self.items = []
        for item in buffers_list:
            item = item.replace('\\', '/')
            name = utils.GetAbbr(item, add_list)
            add_list.append(name)
            self.items.append({'abbr': name, 'path': item})
        return self.items

    def Closed(self, event):
        pass

    def Preview(self, event):
        res = event['res']
        if res == {}:
            return ''
        return utils.Highlight(file_path=res['path'])
