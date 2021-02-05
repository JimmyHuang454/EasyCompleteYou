from loguru import logger
from ECY import utils
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
        if 'show_list' not in context:
            logger.debug('missing params. "show_list"')
            return

        params = context['params']
        current_line = params['buffer_line']
        current_line = bytes(current_line, encoding='utf-8')

        context['next_key'] = str(
            current_line[params['buffer_position']['colum']:],
            encoding='utf-8')

        context['prev_key'] = str(
            current_line[:params['buffer_position']['colum']],
            encoding='utf-8')

        if 'regex' in context and 'filter_key' in context:
            regex = context['regex']
        else:
            regex = r'[\w+]'
            current_colum, filter_words, last_key = utils.MatchFilterKeys(
                context['prev_key'], regex)

            context['filter_key'] = filter_words
            context['start_position'] = {
                'line': params['buffer_position']['line'],
                'colum': current_colum
            }

        context['show_list'] = self.fuzzy_match.FilterItems(
            context['filter_key'],
            context['show_list'],
            isindent=self.is_indent,
            isreturn_match_point=self.is_indent)

        rpc.DoCall('DoCompletion', [context])
