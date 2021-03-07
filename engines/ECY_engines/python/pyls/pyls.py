import re
from loguru import logger
from ECY.lsp import language_server_protocol

global has_pyls

try:
    import pyls
    has_pyls = True
except:
    has_pyls = False


class Operate(object):
    """
    """
    def __init__(self):
        self.engine_name = 'pyls'
        self._did_open_list = {}
        self._start_server()

    def _start_server(self):
        global has_pyls
        if has_pyls is False:
            raise
        self._lsp = language_server_protocol.LSP()
        starting_cmd = 'pyls'
        self._lsp.StartJob(starting_cmd)
        temp = self._lsp.initialize()
        self._lsp.GetResponse(temp['Method'],
                              timeout=5)  # failed to load if timeout
        self.completion_cache = []

    def _did_open_or_change(self, context):
        uri = context['params']['buffer_path']
        text = context['params']['buffer_content']
        text = '\n'.join(text)
        uri = self._lsp.PathToUri(uri)
        version = context['params']['buffer_id']
        # LSP requires the edit-version
        if uri not in self._did_open_list:
            return_id = self._lsp.didopen(uri, 'c', text, version=version)
            self._did_open_list[uri] = {}
        else:
            return_id = self._lsp.didchange(uri, text, version=version)

    def _waitting_for_response(self, method_, version_id):
        # {{{
        while 1:
            try:
                # GetTodo() will only wait for 5s,
                # after that will raise an erro
                return_data = None
                return_data = self._lsp.GetResponse(method_, timeout=5)
                if return_data['id'] == version_id:
                    break
            except:  # noqa
                return None
        return return_data
        # }}}

    def OnBufferEnter(self, context):
        self._did_open_or_change(context)

    def OnCompletion(self, context):
        self._did_open_or_change(context)
        params = context['params']
        uri = params['buffer_path']
        uri = self._lsp.PathToUri(uri)

        start_position = params['buffer_position']
        current_start_postion = {
            'line': start_position['line'],
            'character': start_position['colum']
        }

        temp = self._lsp.completion(uri, current_start_postion)
        return_data = self._waitting_for_response(temp['Method'], temp['ID'])

        if return_data is None:
            return

        if return_data['result'] is None:
            return

        self.completion_cache = []
        for item in return_data['result']['items']:
            results_format = {
                'abbr': item['label'],
                'word': item['insertText'],
                'kind': '',
                'menu': '',
                'info': '',
                'user_data': ''
            }
            results_format['kind'] = self._lsp.GetKindNameByNumber(
                item['kind'])
            self.completion_cache.append(results_format)
        logger.debug(return_data)
        context['show_list'] = self.completion_cache
        return context

    def OnInsertLeave(self, context):
        self.OnBufferEnter(context)
        return None
