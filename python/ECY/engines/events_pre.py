from ECY import rpc
from loguru import logger


class Operate():
    """
    """
    def __init__(self):
        pass

    # def OnBufferEnter(self, context):
    #     return context

    def OnCompletion(self, context):
        return context
        if context['params']['buffer_id'] != rpc.DoCall(
                'GetBufferIDNotChange'):
            logger.debug('filter a context')
            return False
        return context
