import threading
from loguru import logger
from ECY.lsp import language_server_protocol
from ECY import rpc


class Operate(object):
    """
    """
    def __init__(self):
        self.engine_name = 'pyls'
        self._did_open_list = {}
        self._start_server()

    def _start_server(self):
        self._lsp = language_server_protocol.LSP()
        starting_cmd = 'clangd'
        starting_cmd += ' --limit-results=500 --offset-encoding=utf-8'
        self._lsp.StartJob(starting_cmd)
        temp = self._lsp.initialize()
        self._lsp.GetResponse(temp['Method'],
                              timeout_=5)  # failed to load if timeout
        threading.Thread(target=self._handle_log_msg, daemon=True).start()
        self.completion_cache = []
        self._lsp.initialized()

    def _handle_log_msg(self):
        while 1:
            try:
                response = self._lsp.GetResponse('window/logMessage',
                                                 timeout_=-1)
                logger.debug(response)
            except:
                pass

    def _did_open_or_change(self, context):
        # {{{
        uri = context['params']['buffer_path']
        text = context['params']['buffer_content']
        text = "\n".join(text)
        uri = self._lsp.PathToUri(uri)
        version = context['params']['buffer_id']
        logger.debug(version)
        # LSP requires the edit-version
        if uri not in self._did_open_list:
            return_id = self._lsp.didopen(uri, 'c', text, version=0)
            self._did_open_list[uri] = {}
            self._did_open_list[uri]['change_version'] = 0
        else:
            self._did_open_list[uri]['change_version'] += 1
            return_id = self._lsp.didchange(
                uri, text, version=self._did_open_list[uri]['change_version'])


# }}}

    def _waitting_for_response(self, method_, version_id):
        # {{{
        while 1:
            try:
                # GetTodo() will only wait for 5s,
                # after that will raise an erro
                return_data = None
                return_data = self._lsp.GetResponse(method_, timeout_=5)
                if return_data['id'] == version_id:
                    break
            except:  # noqa
                return None
        return return_data
        # }}}

    # def OnBufferEnter(self, context):
    #     self._did_open_or_change(context)

    def OnCompletion(self, context):
        if rpc.GetVaribal('&filetype') != 'cpp':
            return
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
                'abbr': '',
                'word': '',
                'kind': '',
                'menu': '',
                'info': '',
                'user_data': ''
            }

            results_format['kind'] = self._lsp.GetKindNameByNumber(
                item['kind'])

            item_name = item['filterText']

            if results_format['kind'] == 'File':
                name_len = len(item_name)
                if item_name[name_len - 1] in ['>', '"'] and name_len >= 2:
                    item_name = item_name[:name_len - 1]

            results_format['abbr'] = item_name
            results_format['word'] = item_name

            self.completion_cache.append(results_format)

        context['show_list'] = self.completion_cache
        return context
