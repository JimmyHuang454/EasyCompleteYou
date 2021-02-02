from loguru import logger
from ECY import rpc
from ECY.engines import fuzzy_match


class Operate():
    """
    """
    def __init__(self):
        self.fuzzy_match = fuzzy_match.FuzzyMatch()

    def OnBufferEnter(self, context):
        pass

    def OnCompletion(self, context):
        if 'show_list' not in context or 'start_position' not in context:
            logger.debug('missing params.')
            return

        current_line = rpc.DoCall('GetCurrentLine')
        current_line = bytes(current_line, encoding='utf-8')

        context['next_key'] = str(
            current_line[context['start_position']['colum']:],
            encoding='utf-8')

        context['prev_key'] = str(
            current_line[:context['start_position']['colum']],
            encoding='utf-8')

        context['show_list'] = self.fuzzy_match.FilterItems(
            context['filter_key'], context['show_list'])

        rpc.DoCall('DoCompletion', [context])
        logger.debug(context)
