from ECY import rpc
from ECY.debug import logger


class Operate():
    """
    """
    def __init__(self, default_engine):
        self.default_engine = default_engine['engine_obj']

    def OnCompletion(self, context):
        if context['params']['buffer_id'] != rpc.DoCall(
                'ECY#rpc#rpc_event#GetBufferIDNotChange'):
            logger.debug('filter a outdate context.')
            return False
        context = self.default_engine.OnCompletion(context)
        return context

    def OnBufferEnter(self, context):
        context = self.default_engine.OnBufferEnter(context)
        return context

    def OnInsertLeave(self, context):
        context = self.default_engine.OnInsertLeave(context)
        return context
