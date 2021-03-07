import threading
from ECY import utils
from loguru import logger
from ECY.lsp import language_server_protocol
from ECY import rpc


class Operate(object):
    """
    """
    def __init__(self,
                 name,
                 server_cmd,
                 refresh_regex=r'[\w+]',
                 rootUri=None,
                 rootPath=None,
                 languageId='',
                 workspaceFolders=None,
                 initializationOptions=None):

        self.engine_name = name
        self.server_cmd = server_cmd
        self.refresh_regex = refresh_regex

        # init opts
        self.rootUri = rootUri
        self.rootPath = rootPath
        self.workspaceFolders = workspaceFolders
        self.initializationOptions = initializationOptions
        self.languageId = languageId

        self._did_open_list = {}
        self.results_list = []
        self.workspace_cache = []
        self._diagnosis_cache = []
        self.completion_position_cache = {}
        self.completion_isInCompleted = True
        self.timeout = 5

        self._lsp = language_server_protocol.LSP()
        self._start_server()

    def _start_server(self):
        self._lsp.StartJob(self.server_cmd)

        res = self._lsp.initialize(
            rootUri=self.rootUri,
            rootPath=self.rootPath,
            workspaceFolders=self.workspaceFolders,
            initializationOptions=self.initializationOptions).GetResponse(
                timeout=self.timeout)

        self.capabilities = res['result']['capabilities']

        threading.Thread(target=self._handle_log_msg, daemon=True).start()
        threading.Thread(target=self._get_diagnosis, daemon=True).start()
        threading.Thread(target=self._handle_edit, daemon=True).start()

        self._lsp.initialized()

    def _handle_edit(self):
        while 1:
            try:
                response = self._lsp.GetRequestOrNotification(
                    'workspace/applyEdit', timeout=-1)

                try:
                    applied = rpc.DoCall('ECY#code_action#ApplyEdit',
                                         [response['params']['edit']])
                    if applied != 0:
                        applied = False
                    else:
                        applied = True
                except Exception as e:
                    logger.exception(e)
                    applied = False

                logger.debug(response)
                self._lsp.applyEdit_response(response['id'], applied)
            except:
                pass

    def _handle_file_status(self):
        # clangd 8+
        while 1:
            try:
                response = self._lsp.GetRequestOrNotification(
                    'textDocument/clangd.fileStatus', timeout=-1)
                res_path = response['params']['uri']
                res_path = self._lsp.UriToPath(res_path)
                current_buffer_path = rpc.DoCall(
                    'ECY#utils#GetCurrentBufferPath')
                if res_path == current_buffer_path:
                    self._show_msg(response['params']['state'])
            except:
                pass

    def _show_msg(self, msg):
        rpc.DoCall('ECY#utils#echo', ['[%s] %s' % (self.engine_name, msg)])

    def _handle_log_msg(self):
        while 1:
            try:
                response = self._lsp.GetRequestOrNotification(
                    'window/logMessage', timeout=-1)
                msg = response['params']['message']
                if msg.find('compile_commands') != -1:  # clangd 12+
                    self._show_msg(msg.split('\n'))
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
            self._lsp.didopen(uri, self.languageId, text, version=version)
            self._did_open_list[uri] = {'buffer_id': version}
        else:
            self._lsp.didchange(uri, text, version=version)
            self._did_open_list[uri]['buffer_id'] = version


# }}}

    def OnBufferEnter(self, context):
        self._did_open_or_change(context)
        # self._change_workspace_folder(context)

    def _change_workspace_folder(self, context):
        temp = rpc.DoCall('ECY#rooter#GetCurrentBufferWorkSpace')
        if temp not in self.workspace_cache and temp != '':
            self.workspace_cache.append(temp)
            add_workspace = {'uri': self._lsp.PathToUri(temp), 'name': temp}
            self._lsp.didChangeWorkspaceFolders(add_workspace=[add_workspace])

    def OnTextChanged(self, context):
        self._did_open_or_change(context)

    def OnWorkSpaceSymbol(self, context):
        self._lsp.workspaceSymbos()  # not works in clangd

    def OnDocumentSymbol(self, context):
        params = context['params']
        uri = params['buffer_path']
        uri = self._lsp.PathToUri(uri)
        self._lsp.documentSymbos(uri)

    def _signature_help(self, res):
        res = res['result']
        if len(res) != 0:
            rpc.DoCall('ECY#signature_help#Show', [res])

    def OnItemSeleted(self, context):
        if 'completionProvider' not in self.capabilities or 'resolveProvider' not in self.capabilities[
                'completionProvider'] or self.capabilities[
                    'completionProvider']['resolveProvider'] is False:
            logger.debug('server are not supported.')
            return
        ECY_item_index = context['params']['ECY_item_index']
        if (len(self.results_list) - 1) > ECY_item_index:
            return
        self._lsp.completionItem_resolve(
            self.results_list[ECY_item_index]).GetResponse(
                timeout=self.timeout, callback=self._on_item_seleted_cb)

    def _on_item_seleted_cb(self, res):
        # TODO
        pass

    def OnCompletion(self, context):
        if 'completionProvider' not in self.capabilities:
            self._show_msg('OnCompletion are not supported.')
            return

        if 'triggerCharacters' in self.capabilities['completionProvider']:
            self.trigger_key = self.capabilities['completionProvider'][
                'triggerCharacters']
        else:
            self.trigger_key = []
        context['trigger_key'] = self.trigger_key

        self.signature_help_triggerCharacters = []
        if 'signatureHelpProvider' in self.capabilities:
            if 'triggerCharacters' in self.capabilities[
                    'signatureHelpProvider']:
                self.signature_help_triggerCharacters.extend(
                    self.capabilities['signatureHelpProvider']
                    ['triggerCharacters'])

            if 'retriggerCharacters' in self.capabilities[
                    'signatureHelpProvider']:
                self.signature_help_triggerCharacters.extend(
                    self.capabilities['signatureHelpProvider']
                    ['retriggerCharacters'])

        self._did_open_or_change(context)  # update buffer to server

        params = context['params']
        uri = params['buffer_path']
        uri = self._lsp.PathToUri(uri)

        start_position = params['buffer_position']

        current_position_cache = utils.IsNeedToUpdate(context,
                                                      self.refresh_regex)

        #############
        #  signatureHelp  #
        #############
        if current_position_cache[
                'prev_string_last_key'] in self.signature_help_triggerCharacters:
            current_start_postion = {
                'line': start_position['line'],
                'character': start_position['colum']
            }
            self._lsp.signatureHelp(uri, current_start_postion).GetResponse(
                timeout=self.timeout, callback=self._signature_help)

        current_start_postion = {
            'line': start_position['line'],
            'character': current_position_cache['current_colum']
        }

        #############
        #  completion  #
        #############
        context['show_list'] = self.results_list
        if not self.completion_isInCompleted and self.completion_position_cache == current_start_postion:
            return context

        self.results_list = []
        self.completion_position_cache = current_start_postion
        return_data = self._lsp.completion(
            uri, current_start_postion).GetResponse(timeout=self.timeout)

        return_data = return_data['result']
        if return_data is None:
            return context

        if type(return_data) is dict:
            self.completion_isInCompleted = return_data['isIncomplete']
            self.results_list = return_data['items']
        else:
            self.results_list = return_data
            self.completion_isInCompleted = False

        context['show_list'] = self.results_list  # update
        return context

    def DoCmd(self, context):
        params = context['params']
        cmd_params = params['cmd_params']
        uri = self._lsp.PathToUri(params['buffer_path'])
        try:
            open_style = params['open_style']
        except:
            open_style = 'v'

        cmd_name = params['cmd_name']
        if cmd_name == 'switch_source_and_header':  # only supports by clangd
            params = {'uri': uri}
            result = self._lsp._build_send(
                params, 'textDocument/switchSourceHeader').GetResponse(
                    timeout=self.timeout)
            if result['result'] is not None:
                path = self._lsp.UriToPath(result['result'])
                rpc.DoCall('MoveToBuffer', [0, 0, path, open_style])
            else:
                rpc.DoCall('ECY#utils#echo',
                           ["Can not find it's header/source. Try it latter."])
        elif cmd_name == 'get_ast':
            self._get_AST(context)
        elif cmd_name == 'change_setting':
            # TODO
            self._lsp.didChangeConfiguration(
                {'compilationDatabaseChanges': cmd_params['compile_commands']})
        else:
            self._lsp.executeCommand(cmd_name, arguments=cmd_params)

    def _get_diagnosis(self):
        while True:
            try:
                temp = self._lsp.GetRequestOrNotification(
                    'textDocument/publishDiagnostics', timeout=-1)
                self._diagnosis_cache = temp['params']['diagnostics']
                lists = self._diagnosis_analysis(temp['params'])
                rpc.DoCall('ECY#diagnostics#PlaceSign', [{
                    'engine_name': self.engine_name,
                    'res_list': lists
                }])
            except Exception as e:
                logger.exception(e)

    def DoCodeAction(self, context):
        params = context['params']
        uri = self._lsp.PathToUri(params['buffer_path'])
        ranges = params['buffer_range']
        start_position = ranges['start']
        end_position = ranges['end']

        returns = self._lsp.codeAction(
            uri,
            start_position,
            end_position,
            diagnostic=self._diagnosis_cache).GetResponse(timeout=self.timeout)

        context['result'] = returns['result']
        logger.debug(context)
        return context

    def _get_AST(self, context):  # only in clangd
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
        self._lsp._build_send(
            params, 'textDocument/ast').GetResponse(timeout=self.timeout)

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

    def GotoDefinition(self, context):
        if 'definitionProvider' not in self.capabilities:
            self._show_msg('GotoDefinition are not supported.')
            return
        params = context['params']
        uri = params['buffer_path']
        uri = self._lsp.PathToUri(uri)
        start_position = params['buffer_position']
        position = {
            'line': start_position['line'],
            'character': start_position['colum']
        }

        res = self._lsp.definition(position,
                                   uri).GetResponse(timeout=self.timeout)
        res = res['result']
        if res is None:
            res = []
        rpc.DoCall('ECY#goto#Do', [res])

    def GotoTypeDefinition(self, context):
        if 'typeDefinitionProvider' not in self.capabilities:
            self._show_msg('GotoTypeDefinition are not supported.')
            return
        params = context['params']
        uri = params['buffer_path']
        uri = self._lsp.PathToUri(uri)
        start_position = params['buffer_position']
        position = {
            'line': start_position['line'],
            'character': start_position['colum']
        }

        res = self._lsp.typeDefinition(position,
                                       uri).GetResponse(timeout=self.timeout)
        res = res['result']
        if res is None:
            res = []
        rpc.DoCall('ECY#goto#Do', [res])

    def GotoImplementation(self, context):
        if 'implementationProvider' not in self.capabilities:
            self._show_msg('GotoImplementation are not supported.')
            return
        params = context['params']
        uri = params['buffer_path']
        uri = self._lsp.PathToUri(uri)
        start_position = params['buffer_position']
        position = {
            'line': start_position['line'],
            'character': start_position['colum']
        }

        res = self._lsp.implementation(position,
                                       uri).GetResponse(timeout=self.timeout)
        res = res['result']
        if res is None:
            res = []
        rpc.DoCall('ECY#goto#Do', [res])

    def GotoDeclaration(self, context):
        if 'declarationProvider' not in self.capabilities:
            self._show_msg('GotoDeclaration are not supported.')
            return
        params = context['params']
        uri = params['buffer_path']
        uri = self._lsp.PathToUri(uri)
        start_position = params['buffer_position']
        position = {
            'line': start_position['line'],
            'character': start_position['colum']
        }

        res = self._lsp.declaration(position,
                                    uri).GetResponse(timeout=self.timeout)
        res = res['result']
        if res is None:
            res = []
        rpc.DoCall('ECY#goto#Do', [res])

    def OnHover(self, context):
        if 'hoverProvider' not in self.capabilities:
            self._show_msg('Hover are not supported.')
            return
        params = context['params']
        uri = params['buffer_path']
        uri = self._lsp.PathToUri(uri)
        start_position = params['buffer_position']
        position = {
            'line': start_position['line'],
            'character': start_position['colum']
        }

        res = self._lsp.hover(position, uri).GetResponse(timeout=self.timeout)

    def FindReferences(self, context):
        if 'referencesProvider' not in self.capabilities:
            self._show_msg('FindReferences are not supported.')
            return
        params = context['params']
        uri = params['buffer_path']
        uri = self._lsp.PathToUri(uri)
        start_position = params['buffer_position']
        position = {
            'line': start_position['line'],
            'character': start_position['colum']
        }

        res = self._lsp.references(position,
                                   uri).GetResponse(timeout=self.timeout)
        res = res['result']
        if res is None:
            res = []
        rpc.DoCall('ECY#goto#Do', [res])
