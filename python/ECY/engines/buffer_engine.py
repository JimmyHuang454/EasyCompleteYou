import re


class Operate(object):
    """
    """
    def __init__(self):
        self.engine_name = 'buffer'
        self.cache_dict = {}
        self.res_list = []

    def _update_cache(self, context):
        params = context['params']
        line_text = '\n'.join(params['buffer_content'])
        path = params['buffer_path']
        self.cache_dict[path] = line_text
        temp = []
        for item in self.cache_dict:
            temp.extend(re.findall(r'\w+', self.cache_dict[item]))

        temp = list(set(temp))

        self.res_list = []
        for item in temp:
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
            results_format['kind'] = '[B]'
            self.res_list.append(results_format)

    def OnBufferEnter(self, context):
        self._update_cache(context)
        return context

    def OnCompletion(self, context):
        context['buffer_show_list'] = self.res_list
        return context

    def OnInsertLeave(self, context):
        self._update_cache(context)
        return context
