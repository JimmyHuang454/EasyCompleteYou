import re
from loguru import logger
from ECY import rpc


class Operate(object):
    """
    """
    def __init__(self):
        self.engine_name = 'label'
        self.content_cache = []

    def OnBufferEnter(self, context):
        line_text = '\n'.join(rpc.DoCall('GetCurrentBufferContent'))
        items_list = list(set(re.findall(r'\w+', line_text)))
        self.content_cache = []
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
            self.content_cache.append(results_format)
        return None

    def OnCompletion(self, context):
        context['show_list'] = self.content_cache
        context['filter_key'] = 're'
        current_position = rpc.DoCall('GetCurrentLineAndPosition')
        context['start_position'] = current_position
        return context
