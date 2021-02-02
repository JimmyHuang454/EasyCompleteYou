from loguru import logger
from ECY import rpc


class Operate(object):
    """
    """
    def __init__(self):
        self.engine_name = 'label'

    def OnBufferEnter(self, context):
        return context

    def OnCompletion(self, context):
        context['show_list'] = ['234', '34']
        context['filter_key'] = '3'
        current_position = rpc.DoCall('GetCurrentLineAndPosition')
        context['start_position'] = current_position
        return context
