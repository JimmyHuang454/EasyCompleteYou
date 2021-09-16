from ECY import rpc
from ECY.debug import logger


class DefaultEngine(object):
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
        # print('Closed', event)
        res = event['res']
        if res != {}:
            pass
        rpc.DoCall('ECho', [str(event)])

    def Preview(self, event):
        return str(event)
