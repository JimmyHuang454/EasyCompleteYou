from ECY import rpc
from ECY.engines import buffer_engine
from loguru import logger


class Operate():
    """
    """
    def __init__(self):
        self.buffer_engine = buffer_engine.Operate()

    def OnCompletion(self, context):
        context = self.buffer_engine.OnCompletion(context)
        if context['params']['buffer_id'] != rpc.DoCall(
                'GetBufferIDNotChange'):
            logger.debug('filter a context')
            return False
        return context

    def OnBufferEnter(self, context):
        context = self.buffer_engine.OnBufferEnter(context)
        return context

    def OnInsertLeave(self, context):
        context = self.buffer_engine.OnInsertLeave(context)
        return context
