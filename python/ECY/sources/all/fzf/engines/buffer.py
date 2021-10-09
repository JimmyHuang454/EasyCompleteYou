from ECY import rpc
from ECY import utils
from ECY.debug import logger


class DefaultEngine(object):
    """
    """
    def __init__(self, event_id):
        self.event_id = event_id

        self.items = []
        self.engine_name = 'Buffer'

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
        # print('Closed', event)
        res = event['res']
        if res == {}:
            return
        rpc.DoCall('ECho', [str(event['res'])])

    def Preview(self, event):
        return str(event)
