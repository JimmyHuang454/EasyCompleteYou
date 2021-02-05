import re
from loguru import logger
from ECY import rpc


class Operate(object):
    """
    """
    def __init__(self):
        self.engine_name = 'label'
        self.cache_dict = []
        self.cache_string = []

    def OnBufferEnter(self, context):
        line_text = '\n'.join(context['params']['buffer_content'])
        items_list = list(set(re.findall(r'\w+', line_text)))
        self.cache_string.extend(items_list)
        self.cache_string = list(set(self.cache_string))
        self.cache_dict = []
        for item in self.cache_string:
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
            self.cache_dict.append(results_format)
        return None

    def OnCompletion(self, context):
        context['show_list'] = self.cache_dict
        return context

    def OnInsertLeave(self, context):
        self.OnBufferEnter(context)
