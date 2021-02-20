import threading
from ECY import utils
from loguru import logger
from ECY.lsp import language_server_protocol
from ECY import rpc


class Operate(object):
    """
    """
    def __init__(self):
        self.engine_name = 'clangd'
        self._did_open_list = {}
        self.results_list = []
        self.is_InComplete = False
        self.trigger_key = [".", "<", ">", ":", "\"", "/"]
        self.workspace_cache = []
        self._diagnosis_cache = []

        ###############
        #  user opts  #
        ###############
        self.user_clangd_path = 'g:ECY_clangd_cmd'
        self._start_server()

    # def OnRequest(self, context):
    #     self.engine_name = context['engine_name']
    #     return context

    def _start_server(self):
        has_ECY_windows_clangd_pip = None

        if rpc.DoCall('exists', [self.user_clangd_path]):
            starting_cmd = rpc.GetVaribal(self.user_clangd_path)
        else:
            try:
                import ECY_clangd
                has_ECY_windows_clangd_pip = True
            except:
                has_ECY_windows_clangd_pip = False
            starting_cmd = ECY_clangd.exe_path

        self._lsp = language_server_protocol.LSP()
        starting_cmd += ' --limit-results=500'
        self._lsp.StartJob(starting_cmd)
        temp = self._lsp.PathToUri(
            rpc.DoCall('ECY#rooter#GetCurrentBufferWorkSpace'))
        self.workspace_cache.append(temp)
        temp = self._lsp.initialize(rootUri=self.workspace_cache[0])
        self._lsp.GetResponse(temp['Method'], timeout_=5)
        threading.Thread(target=self._handle_log_msg, daemon=True).start()
        threading.Thread(target=self._get_diagnosis, daemon=True).start()
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
            return_id = self._lsp.didopen(uri, 'c', text, version=version)
            self._did_open_list[uri] = {'buffer_id': version}
        else:
            return_id = self._lsp.didchange(uri, text, version=version)
            self._did_open_list[uri]['buffer_id'] = version


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

    def OnBufferEnter(self, context):
        self._did_open_or_change(context)
        temp = rpc.DoCall('ECY#rooter#GetCurrentBufferWorkSpace')
        if temp not in self.workspace_cache and temp != '':
            self.workspace_cache.append(temp)
            add_workspace = {'uri': self._lsp.PathToUri(temp), 'name': temp}
            self._lsp.didChangeWorkspaceFolders(add_workspace=[add_workspace])

    def OnTextChanged(self, context):
        self._did_open_or_change(context)

    def OnWorkSpaceSymbol(self, context):
        self._lsp.workspaceSymbos()

    def OnCompletion(self, context):
        self._did_open_or_change(context)
        context['trigger_key'] = self.trigger_key
        params = context['params']
        uri = params['buffer_path']
        uri = self._lsp.PathToUri(uri)

        start_position = params['buffer_position']

        current_cache = utils.IsNeedToUpdate(context, r'[\w+]')

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

        self.is_InComplete = return_data['result']['isIncomplete']

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

            try:
                if item['insertTextFormat'] == 2:
                    temp = item['insertText']
                    if '$' in temp or '(' in temp or '{' in temp:
                        temp = temp.replace('{\\}', '\{\}')
                        results_format['snippet'] = temp
                        results_format['kind'] += '~'
            except:
                pass

            detail = []
            if 'detail' in item:
                detail = item['detail'].split('\n')
                if len(detail) == 2:
                    results_format['menu'] = detail[1]
                else:
                    results_format['menu'] = item['detail']

            document = []
            if 'label' in item:
                temp = item['label']
                if temp[0] == ' ':
                    temp = temp[1:]
                if results_format['kind'] == 'Function':
                    temp = detail[0] + ' ' + temp
                document.append(temp)
                document.append('')

            if 'documentation' in item:
                if type(item['documentation']) is str:
                    temp = item['documentation'].split('\n')
                elif type(item['documentation']) is dict:
                    temp = item['documentation']['value'].split('\n')

                document.extend(temp)

            results_format['info'] = '\n'.join(document)

            self.results_list.append(results_format)
        context['show_list'] = self.results_list
        return context

    def DoCmd(self, context):
        params = context['params']
        uri = self._lsp.PathToUri(params['buffer_path'])
        try:
            open_style = params['open_style']
        except:
            open_style = 'v'

        cmd_name = params['cmd_name']
        if cmd_name == 'switch_source_and_header':  # only supports by clangd
            params = {'uri': uri}
            temp = self._lsp._build_send(params,
                                         'textDocument/switchSourceHeader')
            temp = self._lsp.GetResponse(temp['Method'], timeout_=5)
            if temp['result'] is not None:
                path = self._lsp.UriToPath(temp['result'])
                rpc.DoCall('MoveToBuffer', [0, 0, path, open_style])
            else:
                rpc.DoCall('ECY#utils#echo',
                           ["Can not find it's header/source. Try it latter."])
        elif cmd_name == 'get_ast':
            self._get_AST(context)
        else:
            self._lsp.executeCommand(cmd_name, arguments=params['param_list'])

    def _get_diagnosis(self):
        while True:
            try:
                temp = self._lsp.GetResponse('textDocument/publishDiagnostics',
                                             timeout_=-1)
                self._diagnosis_cache = temp['params']['diagnostics']
                lists = self._diagnosis_analysis(temp['params'])
                rpc.DoCall('ECY#diagnostics#PlaceSign',
                           [{
                               'engine_name': self._get_engine_name(),
                               'res_list': lists
                           }])
            except Exception as e:
                logger.exception(e)

    def _get_engine_name(self):
        if self.engine_name is None:
            return 'nothing'
        return self.engine_name

    def DoCodeAction(self, context):
        params = context['params']
        uri = self._lsp.PathToUri(params['buffer_path'])
        start_position = {'line': 0, 'character': 0}
        end_position = {'line': 0, 'character': 0}

        if self._diagnosis_cache == []:
            return
        returns = self._lsp.codeAction(uri,
                                       start_position,
                                       end_position,
                                       diagnostic=self._diagnosis_cache)
        returns = self._lsp.GetResponse(returns['Method'], timeout_=5)
        context['result'] = returns
        return context

    def _get_buffer_version(self, uri):
        if uri not in self._did_open_list:
            return 1
        return self._did_open_list[uri]['buffer_id']

    def _code_action_analysis(self, results):
        change_list = []
        command_list = []
        for item in results:
            if 'diagnostics' in item:
                for item2 in item['edit']:
                    if 'changes' in item2:
                        for change in item2['changes']:
                            path = self._lsp.UriToPath(change)
                            change_list.append({
                                'file_path': path,
                                'edit': item2['changes'][change]
                            })
                    if 'command' in item2:
                        # TODO
                        pass
            else:
                # TODO
                pass
        return {'change_list': change_list, 'command_list': command_list}

    def _get_AST(self, context):
        uri = context['params']['buffer_path']
        uri = self._lsp.PathToUri(uri)

        text = context['params']['buffer_content']
        text = "\n".join(text)

        textDocument = {
            'uri': uri,
            'languageId': 'c',
            'text': text,
            'version': 0
        }

        ranges = {
            'start': {
                'line': 0,
                'character': 0
            },
            'end': {
                'line': 0,
                'character': 0
            }
        }

        params = {'textDocument': textDocument, 'range': ranges}
        temp = self._lsp._build_send(params, 'textDocument/ast')
        self._lsp.GetResponse(temp['Method'], timeout_=5)

    def _diagnosis_analysis(self, params):
        results_list = []
        file_path = self._lsp.UriToPath(params['uri'])
        if file_path == '':
            return results_list
        for item in params['diagnostics']:
            ranges = item['range']
            start_line = ranges['start']['line'] + 1
            start_colum = ranges['start']['character']
            end_line = ranges['end']['line'] + 1
            end_colum = ranges['end']['character']
            pos_string = '[%s, %s]' % (str(start_line), str(start_colum))

            position = {
                'line': start_line,
                'range': {
                    'start': {
                        'line': start_line,
                        'colum': start_colum
                    },
                    'end': {
                        'line': end_line,
                        'colum': end_colum
                    }
                }
            }
            diagnosis = item['message']
            if item['severity'] == 1:
                kind = 1
            else:
                kind = 2
            kind_name = self._lsp.GetDiagnosticSeverity(item['severity'])
            temp = [{
                'name': '1',
                'content': {
                    'abbr': diagnosis
                }
            }, {
                'name': '2',
                'content': {
                    'abbr': kind_name
                }
            }, {
                'name': '3',
                'content': {
                    'abbr': file_path
                }
            }, {
                'name': '4',
                'content': {
                    'abbr': pos_string
                }
            }]
            temp = {
                'items': temp,
                'type': 'diagnosis',
                'file_path': file_path,
                'kind': kind,
                'diagnostics': diagnosis,
                'position': position
            }
            results_list.append(temp)
        return results_list
