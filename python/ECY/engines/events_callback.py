from ECY.debug import logger
from ECY import utils
from ECY import rpc
from ECY.engines import fuzzy_match


class Operate():
    """
    """
    def __init__(self, default_engine):
        self.show_list_len = 15
        self.fuzzy_match = fuzzy_match.FuzzyMatch(
            max_len_2_show=self.show_list_len)
        self.is_indent = True
        self.default_engine = default_engine['engine_obj']

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

        if 'regex' in context:
            regex = context['regex']
        else:  # default one
            regex = r'[\w+]'

        current_colum, filter_words, last_key = utils.MatchFilterKeys(
            context['prev_key'], regex)

        context['filter_key'] = filter_words
        context['filter_key_len'] = len(filter_words)
        context['start_position'] = {
            'line': params['buffer_position']['line'],
            'colum': current_colum
        }

        ########################
        #  completion resolve  #
        ########################
        i = 0
        for item in context['show_list']:
            item['ECY_item_index'] = i
            i += 1

        if 'is_filter' not in context:
            context['is_filter'] = True

        if context['is_filter']:
            res_list = self.fuzzy_match.FilterItems(
                context['filter_key'],
                context['show_list'],
                isindent=self.is_indent,
                isreturn_match_point=self.is_indent)

        if 'must_show' not in context:
            if 'trigger_key' in context:
                if last_key in context['trigger_key']:
                    context['must_show'] = True
                else:
                    context['must_show'] = False
            else:
                context['must_show'] = False

        # show_list_len = self.show_list_len - len(res_list)
        if len(res_list) == 0:
            res_list = self.fuzzy_match.FilterItems(
                context['filter_key'],
                context['buffer_show_list'],
                isindent=self.is_indent,
                isreturn_match_point=self.is_indent)

        context['show_list'] = res_list
        rpc.DoCall('ECY#completion#Open', [context])
