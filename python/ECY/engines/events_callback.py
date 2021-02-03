from loguru import logger
from ECY import rpc
from ECY.engines import fuzzy_match


class Operate():
    """
    """
    def __init__(self):
        self.fuzzy_match = fuzzy_match.FuzzyMatch()
        self.is_get_opts_done = False
        self.is_indent = True

    def _get_opts(self):
        if self.is_done:
            return
        self.is_get_opts_done = True
        if rpc.GetVaribal('g:has_floating_windows_support') == 'has_no':
            self.is_indent = False

    def OnBufferEnter(self, context):
        self._get_opts()

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
            context['filter_key'],
            context['show_list'],
            isindent=self.is_indent,
            isreturn_match_point=self.is_indent)

        rpc.DoCall('DoCompletion', [context])
