import threading
from ECY import utils
from loguru import logger
from ECY.lsp import language_server_protocol
from ECY import rpc


class Operate(object):
    """
    """
    def __init__(self):
        self.trigger_key = ['.', ':']
        self._lsp = language_server_protocol.LSP()

    def _is_need_to_update(self, context, regex):
        params = context['params']
        current_colum = params['buffer_position']['colum']
        current_line = params['buffer_position']['line']
        current_line_content = params['buffer_position']['line_content']
        temp = bytes(current_line_content, encoding='utf-8')
        prev_key = str(temp[:current_colum], encoding='utf-8')

        current_colum, filter_words, last_key = utils.MatchFilterKeys(
            prev_key, regex)
        cache = {
            'current_line': current_line,
            'current_colum': current_colum,
            'line_counts': len(params['buffer_content'])
        }
        return cache

    def OnCompletion(self, context):
        context['trigger_key'] = self.trigger_key
        params = context['params']
        uri = params['buffer_path']
        uri = self._lsp.PathToUri(uri)

        start_position = params['buffer_position']

        current_cache = self._is_need_to_update(context, r'[\#\:\w+]')

        current_start_postion = {
            'line': start_position['line'],
            'character': current_cache['current_colum']
        }

        if 'is_vim_lsp_callback' not in params:
            logger.debug('request')
            params['vim_lsp_position'] = current_start_postion
            params['buffer_content'] = ''
            rpc.DoCall('Vim_lspRequestCompletion', [params])
            return
        else:
            logger.debug('okkkkkkkkkkkk')

        self.results_list = []

        return_data = params['response']

        if return_data is None:
            return

        if return_data['result'] is None:
            return

        # self.is_InComplete = return_data['result']['isIncomplete']

        for item in return_data['result']['items']:
            results_format = {
                'abbr': '',
                'word': '',
                'kind': '',
                'menu': '',
                'info': '',
                'user_data': ''
            }

            results_format['kind'] = self._lsp.GetKindNameByNumber(
                item['kind'])

            item_name = item['label']
            results_format['abbr'] = item_name
            results_format['word'] = item_name

            self.results_list.append(results_format)
        context['show_list'] = self.results_list
        logger.debug(self.results_list)
        return context
