from ECY import rpc
from ECY.engines import buffer_engine
from ECY.debug import logger


class Operate():
    """
    """
    def __init__(self):
        self.buffer_engine = buffer_engine.Operate()

    def OnCompletion(self, context):
        if context['params']['buffer_id'] != rpc.DoCall(
                'ECY#rpc#rpc_event#GetBufferIDNotChange'):
            logger.debug('filter a outdate context.')
            return False
        context = self.buffer_engine.OnCompletion(context)
        return context

    def OnBufferEnter(self, context):
        context = self.buffer_engine.OnBufferEnter(context)
        return context

    def OnInsertLeave(self, context):
        context = self.buffer_engine.OnInsertLeave(context)
        return context
