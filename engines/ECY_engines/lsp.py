import threading
import copy
from ECY import utils
from ECY.debug import logger
from ECY.lsp import language_server_protocol
from ECY.lsp import workspace_edit
from ECY.lsp import messsage_type
from ECY import rpc


class Operate(object):
    def __init__(self,
                 name,
                 starting_cmd=None,
                 refresh_regex=r'[\w+]',
                 rootUri=None,
                 rootPath=None,
                 languageId='',
                 workspaceFolders=None,
                 use_completion_cache=True,
                 use_completion_cache_position=False,
                 initializationOptions=None):

        self.engine_name = name

        if starting_cmd is None:
            starting_cmd = utils.GetEngineConfig(self.engine_name, 'cmd')

        if starting_cmd is None or starting_cmd == '':
            raise ValueError("missing cmd.")

        logger.debug(starting_cmd)
        self._lsp = language_server_protocol.LSP(timeout=10)
        self.use_completion_cache = use_completion_cache
        self.use_completion_cache_position = use_completion_cache_position

        self.starting_cmd = starting_cmd
        self.refresh_regex = refresh_regex

        # in favour of `rootUri`.
        if rootPath is None:
            self.rootPath = rpc.DoCall('ECY#rooter#GetCurrentBufferWorkSpace')
        else:
            self.rootPath = rootPath

        if rootUri is None:
            self.rootUri = self._lsp.PathToUri(self.rootPath)
        else:
            self.rootUri = rootUri

        if workspaceFolders is None:
            self.workspaceFolders = [{
                'uri': self.rootUri,
                'name': 'ECY_' + self.rootPath
            }]
        else:
            self.workspaceFolders = workspaceFolders

        if initializationOptions is None:
            initializationOptions = utils.GetEngineConfig(
                self.engine_name, 'initializationOptions')
            if initializationOptions == '':
                initializationOptions = None
        self.initializationOptions = initializationOptions

        self.languageId = languageId

        self._did_open_list = {}
        self._diagnosis_cache = []
        self.results_list = []
        self.rename_info = {}
        self.rename_id = 0
        self.workspace_cache = []
        self.completion_position_cache = {}
        self.completion_isInCompleted = False
        self.current_seleted_item = {}
        self.code_action_cache = None
        self.workspace_edit_undo = None

        self._start_server()
        self._get_format_config()

    def _start_server(self):
        self._lsp.StartJob(self.starting_cmd)

        res = self._lsp.initialize(
            rootUri=self.rootUri,
            rootPath=self.rootPath,
            workspaceFolders=self.workspaceFolders,
            initializationOptions=self.initializationOptions).GetResponse()

        self.capabilities = res['result']['capabilities']

        threading.Thread(target=self._handle_log_msg, daemon=True).start()
        threading.Thread(target=self._handle_show_msg, daemon=True).start()
        threading.Thread(target=self._get_diagnosis, daemon=True).start()
        threading.Thread(target=self._get_registerCapability,
                         daemon=True).start()
        threading.Thread(target=self._handle_edit, daemon=True).start()

        self.signature_help_triggerCharacters = []
        if 'signatureHelpProvider' in self.capabilities:
            temp = self.capabilities['signatureHelpProvider']
            if 'triggerCharacters' in temp:
                self.signature_help_triggerCharacters.extend(
                    temp['triggerCharacters'])

            if 'retriggerCharacters' in temp:
                self.signature_help_triggerCharacters.extend(
                    temp['retriggerCharacters'])

        self._lsp.initialized()

    def _get_format_config(self):
        self.engine_format_setting = utils.GetEngineConfig(
            self.engine_name, 'lsp_formatting')
        if self.engine_format_setting == None:
            self.engine_format_setting = utils.GetEngineConfig(
                'GLOBAL_SETTING', 'lsp_formatting')

    def _handle_edit(self):
        while 1:
            try:
                response = self._lsp.GetRequestOrNotification(
                    'workspace/applyEdit')

                try:
                    res = workspace_edit.WorkspaceEdit(
                        response['params']['edit'])
                    self._do_action(res)
                    applied = True
                except Exception as e:
                    logger.exception(e)
                    applied = False

                logger.debug(response)
                self._lsp.applyEdit_response(response['id'], applied)
            except Exception as e:
                logger.exception(e)

    def UndoAction(self, context):
        if self.workspace_edit_undo is None:
            return
        rpc.DoCall('ECY#code_action#Undo_cb', [self.workspace_edit_undo])
        self.workspace_edit_undo = None

    def _do_action(self, res):
        for item in res:
            if 'text' in res[item]:
                res[item]['new_text_len'] = len(res[item]['text'])
                del res[item]['text']

        self.workspace_edit_undo = copy.deepcopy(res)

        for item in res:
            if 'undo_text' in res[item]:
                del res[item]['undo_text']
        rpc.DoCall('ECY#utils#ApplyTextEdit', [res])

    def _handle_file_status(self):
        # clangd 8+
        while 1:
            try:
                response = self._lsp.GetRequestOrNotification(
                    'textDocument/clangd.fileStatus')
                res_path = response['params']['uri']
                res_path = self._lsp.UriToPath(res_path)
                current_buffer_path = rpc.DoCall(
                    'ECY#utils#GetCurrentBufferPath')
                if res_path == current_buffer_path:
                    self._show_msg(response['params']['state'])
            except:
                pass

    def _show_msg(self, msg):
        if type(msg) is str:
            msg = msg.split('\n')
        res = ['[%s]' % self.engine_name]
        res.extend(msg)
        rpc.DoCall('ECY#utils#echo', [res])

    def _handle_show_msg(self):
        if not utils.GetEngineConfig('GLOBAL_SETTING', 'lsp.showMessage'):
            return
        while 1:
            try:
                response = self._lsp.GetRequestOrNotification(
                    'window/showMessage')
                res = response['params']
                msg = res['message']
                self._show_msg(
                    "{ %s } %s" %
                    (messsage_type.MESSAGE_TYPE[res['type']], msg.split('\n')))
            except Exception as e:
                logger.exception(e)

    def _handle_log_msg(self):
        while 1:
            try:
                response = self._lsp.GetRequestOrNotification(
                    'window/logMessage')
                msg = response['params']['message']
                if msg.find('compile_commands') != -1:  # clangd 12+
                    self._show_msg(msg.split('\n'))
                logger.debug(response)
            except Exception as e:
                logger.exception(e)

    def _did_open_or_change(self, context):
        # {{{
        uri = context['params']['buffer_path']
        text = context['params']['buffer_content']
        text = "\n".join(text)
        try:
            uri = self._lsp.PathToUri(uri)
        except Exception as e:  # wrong uri while using fugitive.
            logger.exception(e)
            return
        version = context['params']['buffer_id']
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
        self._change_workspace_folder(context)
        # self.semanticTokens(context)

    def _change_workspace_folder(self, context):
        if 'workspace' not in self.capabilities or 'workspaceFolders' not in self.capabilities[
                'workspace'] or not self.capabilities['workspace'][
                    'workspaceFolders']:
            return

        path = rpc.DoCall('ECY#rooter#GetCurrentBufferWorkSpace')
        if path not in self.workspace_cache and path != '':
            self.workspace_cache.append(path)
            add_workspace = {'uri': self._lsp.PathToUri(path), 'name': path}
            self._lsp.didChangeWorkspaceFolders(add_workspace=[add_workspace])

    def OnTextChanged(self, context):
        self._did_open_or_change(context)

    def SelectionRange(self, context):
        if 'selectionRangeProvider' not in self.capabilities:
            self._show_msg('SelectionRange is not supported.')
            return
        params = context['params']
        uri = params['buffer_path']
        uri = self._lsp.PathToUri(uri)
        start_position = params['buffer_position']
        position = {
            'line': start_position['line'],
            'character': start_position['colum']
        }

        res = self._lsp.selectionRange(position, uri).GetResponse()
        res = res['result']

        if res is not None:
            res = res[0]
            res['path'] = uri
            rpc.DoCall('ECY#selete_range#Do', [res])

    def OnWorkSpaceSymbol(self, context):
        if 'workspaceSymbolProvider' not in self.capabilities:
            self._show_msg('OnWorkSpaceSymbol is not supported.')
            return
        res = self._lsp.workspaceSymbos().GetResponse()  # not works in clangd
        if 'error' in res:
            self._show_msg(res['error']['message'])
            return
        res = res['result']
        if res is None:
            res = []
        self._on_selete(res, show_all=True)

    def _prepare_item(self, res, uri=None, show_all=False):
        res2 = []
        for item in res:
            item['kind'] = self._lsp.GetSymbolsKindByNumber(item['kind'])
            item['abbr'] = item['name']
            if 'location' in item:
                item['path'] = self._lsp.UriToPath(item['location']['uri'])
            else:
                item['path'] = self._lsp.UriToPath(uri)
            child = []
            if 'children' in item and len(item['children']) != 0:
                item['abbr'] = item['abbr'] + '/'
                child = self._prepare_item(item['children'],
                                           uri=uri,
                                           show_all=show_all)
            elif not show_all:
                continue
            res2.append(item)
            res2.extend(child)
        return res2

    def _on_selete(self, res, uri=None, show_all=False):
        res = self._prepare_item(res, uri=uri, show_all=show_all)
        if res == []:
            self._show_msg("Response empty.")
        else:
            rpc.DoCall('ECY#selete#Do', [res])

    def OnDocumentSymbol(self, context):
        if 'documentSymbolProvider' not in self.capabilities:
            self._show_msg('OnDocumentSymbol is not supported.')
            return
        params = context['params']
        uri = params['buffer_path']
        uri = self._lsp.PathToUri(uri)
        res = self._lsp.documentSymbos(uri).GetResponse()
        if 'error' in res:
            self._show_msg(res['error']['message'])
            return
        res = res['result']
        if res is None:
            res = []
        self._on_selete(res, uri=uri)

    def OnTypeFormatting(self, context):
        if 'documentOnTypeFormattingProvider' not in self.capabilities:
            self._show_msg('OnTypeFormatting is not supported.')
            return
        params = context['params']
        uri = params['buffer_path']
        uri = self._lsp.PathToUri(uri)
        start_position = params['buffer_position']
        res = self._lsp.onTypeFormatting(
            uri, start_position['line'], start_position['colum'], '\n',
            self.engine_format_setting).GetResponse()
        if 'error' in res:
            self._show_msg(res['error']['message'])
            return
        res = res['result']
        if res is None:
            return
        res = workspace_edit.WorkspaceEdit({'changes': {uri: res}})
        self._do_action(res)

    def Format(self, context):
        if 'documentFormattingProvider' not in self.capabilities:
            self._show_msg('Format is not supported.')
            return
        params = context['params']
        uri = self._lsp.PathToUri(params['buffer_path'])
        res = self._lsp.formatting(uri,
                                   self.engine_format_setting).GetResponse()
        if 'error' in res:
            self._show_msg(res['error']['message'])
            return

        res = res['result']
        if res is None:
            self._show_msg('nothing to format.')
            return
        res = workspace_edit.WorkspaceEdit({'changes': {uri: res}})
        self._do_action(res)
        self._show_msg('Formatted.')

    def _signature_help(self, res):
        if 'error' in res:
            self._show_msg(res['error']['message'])
            return

        res = res['result']
        if res is None:
            return

        # if len(res['signatures']) == 0:
        #     return

        # i = 0
        # content = []
        # for item in res['signatures']:
        #     content.append("%s. %s" % (i, item['label']))

        # hilight_str = []
        # if 'activeSignature' in res and res['activeSignature'] is not None:
        #     hilight_str.append("%s\." % (res['activeSignature']))
        #     activeSignature = res['activeSignature']
        # else:
        #     activeSignature = {}

        # if 'activeParameter' in res and res['activeParameter'] is not None:
        #     try:
        #         activeParameter = res['parameters'][res['activeParameter']]
        #         hilight_str.append("%s" % (activeParameter))
        #     except:
        #         activeParameter = {}
        # else:
        #     activeParameter = {}

        # if 'documentation' in activeParameter:
        #     content.extend(
        #         self._format_markupContent(activeParameter['documentation']))

        # if 'documentation' in activeSignature:
        #     content.extend(
        #         self._format_markupContent(activeSignature['documentation']))

        if len(res) != 0:
            rpc.DoCall('ECY#signature_help#Show', [res])

    def OnInsertLeave(self, context):
        self.completion_position_cache = {}
        self.completion_isInCompleted = False

    def OnItemSeleted(self, context):
        if 'completionProvider' not in self.capabilities or \
                'resolveProvider' not in self.capabilities['completionProvider'] \
                or self.capabilities['completionProvider']['resolveProvider'] is False:

            logger.debug('OnItemSeleted is not supported.')
            return

        ECY_item_index = context['params']['ECY_item_index']

        if (len(self.results_list) - 1) < ECY_item_index:
            logger.debug('OnItemSeleted wrong')
            return

        self.current_seleted_item = self.results_list[ECY_item_index]

        self._lsp.completionItem_resolve(
            self.current_seleted_item).GetResponse(
                callback=self._on_item_seleted_cb,
                callback_additional_data=self.current_seleted_item)

    def _on_item_seleted_cb(self, res):
        if 'error' in res:
            self._show_msg(res['error']['message'])
            return

        if res['callback_additional_data'] != self.current_seleted_item:
            logger.debug('Outdate item resolve.')
            return

        res = res['result']
        results_format = {
            'abbr': '',
            'word': '',
            'kind': '',
            'menu': '',
            'info': '',
            'user_data': ''
        }

        document = []
        if 'documentation' in res:
            document.extend(self._format_markupContent(res['documentation']))

        detail = []
        if 'detail' in res:
            if type(res['detail']) is str:
                detail = res['detail'].split('\n')
            elif type(res['detail']) is list:
                detail = res['detail']

        results_format['menu'] = detail
        results_format['info'] = document
        logger.debug(results_format)

        rpc.DoCall('ECY#preview_windows#Show', [results_format])

    def OnCompletion(self, context):
        if 'completionProvider' not in self.capabilities:
            # self._show_msg('OnCompletion is not supported.')
            return

        if 'triggerCharacters' in self.capabilities['completionProvider']:
            self.trigger_key = self.capabilities['completionProvider'][
                'triggerCharacters']
        else:
            self.trigger_key = []
        context['trigger_key'] = self.trigger_key
        context['regex'] = self.refresh_regex

        params = context['params']
        uri = params['buffer_path']
        uri = self._lsp.PathToUri(uri)

        start_position = params['buffer_position']

        current_position_cache = utils.IsNeedToUpdate(context,
                                                      self.refresh_regex)

        current_start_postion = {
            'line': start_position['line'],
            'character': start_position['colum']
        }

        if current_position_cache[
                'prev_string_last_key'] in self.signature_help_triggerCharacters:
            self._lsp.signatureHelp(uri, current_start_postion).GetResponse(
                callback=self._signature_help)

        cache_position = {
            'line': start_position['line'],
            'character': current_position_cache['current_colum']
        }

        ################
        #  completion  #
        ################
        if self.use_completion_cache_position:
            current_start_postion['character'] = current_position_cache[
                'current_colum']
        if self.completion_isInCompleted:
            res = self._lsp.completion(uri,
                                       current_start_postion,
                                       triggerKind=3).GetResponse()
        else:
            if self.completion_position_cache == cache_position and self.use_completion_cache:
                # use cache
                for item in self.results_list:
                    if 'textEdit' in item and 'completion_text_edit' in item:
                        item['completion_text_edit']['end']['colum'] = item[
                            'textEdit']['range']['end']['character'] + len(
                                current_position_cache['filter_words'])
                context['show_list'] = self.results_list
                return context
            res = self._lsp.completion(uri,
                                       current_start_postion).GetResponse()

        self.results_list = []
        context['show_list'] = self.results_list
        self.completion_position_cache = cache_position

        if 'error' in res:
            self._show_msg(res['error']['message'])
            return

        res = res['result']
        if res is None:
            return context

        if type(res) is dict:
            self.completion_isInCompleted = res['isIncomplete']
            self.results_list = res['items']
        else:
            self.results_list = res
            self.completion_isInCompleted = False

        for item in self.results_list:
            if 'textEdit' in item:
                ranges = item['textEdit']['range']
                item['completion_text_edit'] = {
                    'newText': item['textEdit']['newText'],
                    'start': {
                        'line': ranges['start']['line'],
                        'colum': ranges['start']['character']
                    },
                    'end': {
                        'line': ranges['end']['line'],
                        'colum': ranges['end']['character']
                    }
                }
        context['show_list'] = self.results_list  # update
        return context

    def ExecuteCommand(self, context):
        if 'executeCommandProvider' not in self.capabilities:
            self._show_msg('executeCommand is not supported.')
            return
        params = context['params']
        cmd_name = params['cmd_name']
        cmd_list = self.capabilities['executeCommandProvider']['commands']

        if cmd_name not in cmd_list:
            self._show_msg("'%s' not found.\n %s" % (cmd_name, str(cmd_list)))
            return
        cmd_params = params['cmd_params']
        self._lsp.executeCommand(cmd_name, arguments=cmd_params)

    def _get_registerCapability(self):
        while True:
            try:
                jobs = self._lsp.GetRequestOrNotification(
                    'client/registerCapability')
                params = jobs['params']
                for item in params['registrations']:
                    logger.debug(item)
                    method = item['method']
                    if method == 'workspace/didChangeWorkspaceFolders':
                        if 'workspace' not in self.capabilities:
                            self.capabilities['workspace'] = {}
                        self.capabilities['workspace'][
                            'workspaceFolders'] = True
                    self._lsp._build_response(None, item['id'])
            except Exception as e:
                logger.exception(e)

    def _get_diagnosis(self):
        while True:
            try:
                temp = self._lsp.GetRequestOrNotification(
                    'textDocument/publishDiagnostics')
                self._diagnosis_cache = temp['params']['diagnostics']
                lists = self._diagnosis_analysis(temp['params'])
                rpc.DoCall('ECY#diagnostics#PlaceSign', [{
                    'engine_name': self.engine_name,
                    'res_list': lists
                }])
            except Exception as e:
                logger.exception(e)

    def CodeActionCallback(self, context):
        params = context['params']
        context = params['context']
        if context != self.code_action_cache or 'result' not in context:
            logger.debug('filtered a CodeActionCallback.')
            return
        res = context['result']
        seleted_item = res[params['seleted_item']]
        if 'edit' in seleted_item:
            res = workspace_edit.WorkspaceEdit(seleted_item['edit'])
            self._do_action(res)
        if 'command' in seleted_item:
            pass  # TODO

    def semanticTokens(self, context):
        if 'semanticTokensProvider' not in self.capabilities:
            return
        params = context['params']
        uri = self._lsp.PathToUri(params['buffer_path'])

        res = self._lsp.semanticTokens('all_delta', uri).GetResponse()
        # TODO

    def DoCodeAction(self, context):
        params = context['params']
        uri = self._lsp.PathToUri(params['buffer_path'])
        ranges = params['buffer_range']
        start_position = ranges['start']
        end_position = ranges['end']
        self.code_action_cache = None

        res = self._lsp.codeAction(
            uri,
            start_position,
            end_position,
            diagnostic=self._diagnosis_cache).GetResponse()

        if len(res) == 0 or res is None:
            rpc.DoCall('ECY#utils#echo', ['Nothing to act.'])
            return
        if 'error' in res:
            self._show_msg(res['error']['message'])
            return

        res = res['result']
        context['result'] = res
        self.code_action_cache = context

        rpc.DoCall('ECY#code_action#Do', [context])

        return context

    def _diagnosis_analysis(self, params):
        results_list = []
        file_path = self._lsp.UriToPath(params['uri'])
        if file_path == '':
            logger.debug("empty file_path")
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
            diagnosis = []
            if type(item['message']) is str:
                diagnosis = item['message'].split('\n')
            elif type(item['message']) is list:
                diagnosis = item['message']

            if 'severity' in item:
                if item['severity'] == 1:
                    kind = 1
                else:
                    kind = 2
            else:
                kind = 1

            kind_name = self._lsp.GetDiagnosticSeverity(kind)
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

    def _goto_response(self, res):
        if 'error' in res:
            self._show_msg(res['error']['message'])
            return

        res = res['result']
        if res is None:
            res = []

        if len(res) == 0:
            self._show_msg("No position to go.")
            return

        for item in res:
            if 'uri' in item:
                item['path'] = self._lsp.UriToPath(item['uri'])

        rpc.DoCall('ECY#goto#Do', [res])

    def GotoDefinition(self, context):
        if 'definitionProvider' not in self.capabilities:
            self._show_msg('GotoDefinition is not supported.')
            return
        params = context['params']
        uri = params['buffer_path']
        uri = self._lsp.PathToUri(uri)
        start_position = params['buffer_position']
        position = {
            'line': start_position['line'],
            'character': start_position['colum']
        }

        res = self._lsp.definition(position, uri).GetResponse()
        self._goto_response(res)

    def GotoTypeDefinition(self, context):
        if 'typeDefinitionProvider' not in self.capabilities:
            self._show_msg('GotoTypeDefinition is not supported.')
            return
        params = context['params']
        uri = params['buffer_path']
        uri = self._lsp.PathToUri(uri)
        start_position = params['buffer_position']
        position = {
            'line': start_position['line'],
            'character': start_position['colum']
        }

        res = self._lsp.typeDefinition(position, uri).GetResponse()
        self._goto_response(res)

    def GotoImplementation(self, context):
        if 'implementationProvider' not in self.capabilities:
            self._show_msg('GotoImplementation is not supported.')
            return
        params = context['params']
        uri = params['buffer_path']
        uri = self._lsp.PathToUri(uri)
        start_position = params['buffer_position']
        position = {
            'line': start_position['line'],
            'character': start_position['colum']
        }

        res = self._lsp.implementation(position, uri).GetResponse()
        self._goto_response(res)

    def GotoDeclaration(self, context):
        if 'declarationProvider' not in self.capabilities:
            self._show_msg('GotoDeclaration is not supported.')
            return
        params = context['params']
        uri = params['buffer_path']
        uri = self._lsp.PathToUri(uri)
        start_position = params['buffer_position']
        position = {
            'line': start_position['line'],
            'character': start_position['colum']
        }

        res = self._lsp.declaration(position, uri).GetResponse()

        self._goto_response(res)

    def OnHover(self, context):
        if 'hoverProvider' not in self.capabilities:
            self._show_msg('Hover is not supported.')
            return
        params = context['params']
        uri = params['buffer_path']
        uri = self._lsp.PathToUri(uri)
        start_position = params['buffer_position']
        position = {
            'line': start_position['line'],
            'character': start_position['colum']
        }

        res = self._lsp.hover(position, uri).GetResponse()
        if 'error' in res:
            self._show_msg(res['error']['message'])
            return

        res = res['result']
        if res is None:
            res = {}

        content = []
        if 'contents' in res:
            content = self._format_markupContent(res['contents'])

        if content == []:
            self._show_msg('Nothing to show')
            return
        rpc.DoCall('ECY#hover#Open', [content])

    def _format_markupContent(self, content):
        # content = res['documentation']
        if content is None:
            return []

        document = []
        kind = ""
        if type(content) is str:
            document = content.split('\n')
        elif type(content) is dict:
            if 'kind' in content:  # MarkupContent
                kind += content['kind']
            if 'language' in content:
                kind += content['language']
            if 'value' in content:
                document.extend(content['value'].split('\n'))
        elif type(content) is list:
            for item in content:
                if type(item) is str:
                    document.extend(item.split('\n'))
                elif type(item) is dict:
                    if 'language' in item:
                        kind += item['language']
                    if 'value' in item:
                        document.extend(item['value'].split('\n'))
        to_show = []
        if kind != "":
            to_show = [kind]
        to_show.extend(document)
        if to_show == [""]:
            return []
        return to_show

    def FindReferences(self, context):
        if 'referencesProvider' not in self.capabilities:
            self._show_msg('FindReferences is not supported.')
            return
        params = context['params']
        uri = params['buffer_path']
        uri = self._lsp.PathToUri(uri)
        start_position = params['buffer_position']
        position = {
            'line': start_position['line'],
            'character': start_position['colum']
        }

        res = self._lsp.references(position, uri).GetResponse()
        self._goto_response(res)

    def GetCodeLens(self, context):
        if 'codeLensProvider' not in self.capabilities:
            self._show_msg('GetCodeLens is not supported.')
            return
        params = context['params']
        uri = params['buffer_path']
        uri = self._lsp.PathToUri(uri)
        res = self._lsp.codeLens(uri).GetResponse()
        if 'error' in res:
            self._show_msg(res['error']['message'])
            return
        # TODO

    def PrepareCallHierarchy(self, context):
        params = context['params']
        if 'callHierarchyProvider' not in self.capabilities:
            self._show_msg('%s is not supported.' % (params['event_name']))
            return
        uri = params['buffer_path']
        uri = self._lsp.PathToUri(uri)
        start_position = params['buffer_position']
        position = {
            'line': start_position['line'],
            'character': start_position['colum']
        }
        res = self._lsp.prepareCallHierarchy(position, uri).GetResponse()
        if 'error' in res:
            self._show_msg(res['error']['message'])
            return

    def _rename_callabck(self, context):
        if 'rename_id' not in context or context[
                'rename_id'] not in self.rename_info:
            return
        rename_info = self.rename_info[context['rename_id']]
        if 'is_quit' in context and context['is_quit']:
            pass  # return
        else:
            rpc.DoCall('ECY#code_action#ApplyEdit', [rename_info['res']])
        del self.rename_info[context['rename_id']]

    def Rename(self, context):
        if 'renameProvider' not in self.capabilities:
            self._show_msg('Rename is not supported.')
            return
        if 'is_callback' in context and context['is_callback']:
            self._rename_callabck(context)
            return
        params = context['params']
        text = params['buffer_content']
        text = "\n".join(text)
        version = params['buffer_id']
        uri = params['buffer_path']
        uri = self._lsp.PathToUri(uri)
        start_position = params['buffer_position']
        position = {
            'line': start_position['line'],
            'character': start_position['colum']
        }

        new_name = params['new_name']

        res = self._lsp.rename(uri, self.languageId, text, version, position,
                               new_name).GetResponse()
        if 'error' in res:
            self._show_msg(res['error']['message'])
            return

        res = res['result']
        if res is None:
            self._show_msg("Failded to get rename info from language server.")
            return
        self.rename_id += 1
        rename_info = {'rename_id': self.rename_id, 'res': res}
        self.rename_info[self.rename_id] = rename_info
        del self.rename_info[self.rename_id]  # for now
        res = workspace_edit.WorkspaceEdit(res)
        self._do_action(res)
