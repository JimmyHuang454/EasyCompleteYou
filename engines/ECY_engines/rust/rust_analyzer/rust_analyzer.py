import threading
from ECY import utils
from loguru import logger
from ECY.lsp import language_server_protocol
from ECY import rpc


class Operate(object):
    """
    """
    def __init__(self):
        self.engine_name = 'rust_analyzer'
        self._did_open_list = {}
        self.results_list = []
        # self.is_InComplete = False
        self.trigger_key = ['.', ':']
        self._start_server()

    def _start_server(self):
        self._lsp = language_server_protocol.LSP()
        starting_cmd = 'rust_analyzer'
        self._lsp.StartJob(starting_cmd)
        temp = self._lsp.initialize(rootUri=self._lsp.PathToUri(
            "C:/Users/qwer/Desktop/vimrc/myproject/test/rust/hello_world"))
        self._lsp.GetResponse(temp['Method'],
                              timeout_=5)  # failed to load if timeout
        threading.Thread(target=self._handle_log_msg, daemon=True).start()
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
            return_id = self._lsp.didopen(uri, 'rust', text, version=version)
            self._did_open_list[uri] = {}
        else:
            return_id = self._lsp.didchange(uri, text, version=version)


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
        # if rpc.GetVaribal('&filetype') != 'cpp':
        #     return
        self._did_open_or_change(context)
        context['trigger_key'] = self.trigger_key
        params = context['params']
        uri = params['buffer_path']
        uri = self._lsp.PathToUri(uri)

        start_position = params['buffer_position']

        current_cache = self._is_need_to_update(context, r'[\w+]')

        current_start_postion = {
            'line': start_position['line'],
            'character': current_cache['current_colum']
        }

        self.results_list = []

        temp = self._lsp.completion(uri, current_start_postion)
        return_data = self._waitting_for_response(temp['Method'], temp['ID'])

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

            item_name = item['filterText']
            results_format['abbr'] = item_name
            results_format['word'] = item_name

            self.results_list.append(results_format)
        context['show_list'] = self.results_list
        return context
