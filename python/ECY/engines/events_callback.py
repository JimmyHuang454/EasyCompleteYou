from loguru import logger
from ECY import rpc


class Operate():
    """
    """
    def __init__(self):
        pass

    def OnBufferEnter(self, context):
        pass

    def OnCompletion(self, context):
        if 'show_list' not in context:
            return

        current_line = rpc.DoCall('GetCurrentLine')
        current_line = bytes(current_line, encoding='utf-8')

        context['next_key'] = str(
            current_line[context['start_position']['colum']:],
            encoding='utf-8')

        context['prev_key'] = str(
            current_line[:context['start_position']['colum']],
            encoding='utf-8')

        rpc.DoCall('DoCompletion', [context])
        logger.debug(context)
