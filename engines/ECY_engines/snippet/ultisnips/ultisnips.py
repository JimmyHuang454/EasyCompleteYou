from loguru import logger
from ECY import rpc
import time


class Operate(object):
    """
    """
    def __init__(self):
        self.engine_name = 'ultisnipts'
        self.snippet_cache = {}

    def _get_filetype(self):
        file_type = rpc.GetVaribal('&filetype')
        if file_type == '':
            return 'nothing'
        return file_type

    def OnBufferEnter(self, context):
        file_type = self._get_filetype()

        if file_type in self.snippet_cache:
            return

        try:
            rpc.DoCall('UltiSnips#SnippetsInCurrentScope', [1])
            snippets = rpc.GetVaribal('g:current_ulti_dict_info')
        except:
            return

        results_list = []
        for trigger, snippet in snippets.items():
            results_format = {
                'abbr': '',
                'word': '',
                'kind': '',
                'menu': '',
                'info': '',
                'user_data': ''
            }
            results_format['word'] = trigger
            results_format['abbr'] = trigger
            results_format['kind'] = '[Snippet]'
            description = snippet['description']
            if not description == '':
                results_format['menu'] = description
            results_list.append(results_format)

        self.snippet_cache[file_type] = results_list
        logger.debug(self.snippet_cache)
        return None

    def OnCompletion(self, context):
        file_type = self._get_filetype()
        # start = time.time()

        # for item in range(1000):
        #     file_type = self._get_filetype()
        # end = time.time()
        # logger.debug((end - start))
        # logger.debug((end - start) / 1000)

        if file_type not in self.snippet_cache:
            return
        context['show_list'] = self.snippet_cache[file_type]
        return context
