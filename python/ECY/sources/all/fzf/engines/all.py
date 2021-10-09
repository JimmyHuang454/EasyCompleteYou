from ECY import rpc
from ECY.debug import logger


class DefaultEngine(object):
    """
    """
    def __init__(self, event_id):
        self.event_id = event_id

        self.item = []
        self.engine_name = 'All'

    def GetSource(self, event):
        params = event['params']

        current_buffer_nr = params['current_buffer_nr']
        buffer_line_list = rpc.DoCall('ECY#utils#GetBufferContent',
                                      [current_buffer_nr])
        logger.debug(buffer_line_list)
        i = 0
        self.item = []
        for item in buffer_line_list:
            self.item.append({'abbr': str(item), 'line': i})
            i += 1
        return self.item

    def Closed(self, event):
        # print('Closed', event)
        res = event['res']
        if res == {}:
            return
        rpc.DoCall('ECho', [str(event['res'])])

    def Preview(self, event):
        return ['abc']
