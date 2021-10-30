from ECY import rpc
from ECY.debug import logger
from ECY_engines.all.fzf import plugin_base


class Operate(plugin_base.Plugin):
    """
    """
    def __init__(self, event_id):
        self.event_id = event_id

        self.items = [{
            'abbr': 'Buffers',
            'des': 'Pick buffer.'
        }, {
            'abbr': 'Lines',
            'des': 'Search in  current buffer line.'
        }, {
            'abbr': 'Rg',
            'des': 'Search file content in a project.'
        }]
        self.engine_name = 'All'

    def RegKeyBind(self):
        return {'enter': self._run}

    def _run(self, event):
        res = event['res']
        if res == {}:
            return
        rpc.DoCall('ClosePopupWindows2')
        rpc.DoCall('Run', [res['abbr']])

    def GetSource(self, event):
        return self.items

    def Preview(self, event):
        res = event['res']
        if res == {}:
            return ''
        for temp in self.items:
            if temp['abbr'] == res['abbr']:
                return temp['des']
        return ''
