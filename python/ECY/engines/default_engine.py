import re
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
        line_text = '\n'.join(rpc.DoCall('GetCurrentBufferContent'))
        items_list = list(set(re.findall(r'\w+', line_text)))
        results_list = []
        for item in items_list:
            # the results_format must at least contain the following keys.
            results_format = {
                'abbr': '',
                'word': '',
                'kind': '',
                'menu': '',
                'info': '',
                'user_data': ''
            }
            results_format['abbr'] = item
            results_format['word'] = item
            results_format['kind'] = '[ID]'
            results_list.append(results_format)

        context['show_list'] = results_list
        context['filter_key'] = 're'
        current_position = rpc.DoCall('GetCurrentLineAndPosition')
        context['start_position'] = current_position
        return context
