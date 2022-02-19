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
                 starting_cmd_argv=None,
                 refresh_regex=r'[\w+]',
                 rootUri=None,
                 rootPath=None,
                 languageId='',
                 workspaceFolders=None,
                 use_completion_cache=False,
                 use_completion_cache_position=True,
                 initializationOptions=None):

        self.engine_name = name

        self.starting_cmd = starting_cmd
        self.starting_cmd_argv = starting_cmd_argv
        self.GetStartCMD()

        self._lsp = language_server_protocol.LSP(timeout=self._get_timeout())
        self.use_completion_cache = use_completion_cache
        self.use_completion_cache_position = use_completion_cache_position

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

        self.workspace_cache = []
        if workspaceFolders is None:
            self.workspaceFolders = None
            temp = {'uri': self.rootUri, 'name': self.rootPath}
            self.workspace_cache.append(temp)
            self.workspaceFolders = [temp]
        else:
            self.workspaceFolders = workspaceFolders

        if initializationOptions is None:
            initializationOptions = utils.GetEngineConfig(
                self.engine_name, 'initializationOptions')
            if initializationOptions == '':
                initializationOptions = None
        self.initializationOptions = initializationOptions

        self.languageId = languageId

        self.enabled_document_link = rpc.GetVaribal(
            'g:ECY_enable_document_link')

        self.enabled_code_lens = rpc.GetVaribal('g:ECY_enable_code_lens')

        self._did_open_list = {}
        self._diagnosis_cache = []
        self.results_list = []
        self.rename_info = {}
        self.semantic_info = {}
        self.rename_id = 0
        self.completion_position_cache = {}
        self.completion_isInCompleted = False
        self.current_seleted_item = {}
        self.code_action_cache = None
        self.workspace_edit_undo = None

        self._start_server()
        self._get_format_config()

    def GetStartCMD(self):
        if self.starting_cmd is None:
            self.starting_cmd = utils.GetEngineConfig(self.engine_name, 'cmd')

        if self.starting_cmd is None or self.starting_cmd == '':
            self.starting_cmd = utils.GetInstallerConfig(self.engine_name)
            logger.debug('installer info:' + str(self.starting_cmd))
            if 'cmd' in self.starting_cmd:
                self.starting_cmd = self.starting_cmd['cmd']
                logger.debug('using installer cmd')
            else:
                self.starting_cmd = utils.GetEngineConfig(
                    self.engine_name, 'cmd2')
                if self.starting_cmd is None or self.starting_cmd == '':
                    raise ValueError("missing cmd.")
                logger.debug('using cmd2')
        else:
            logger.debug('using user setting cmd')

    def _start_server(self):
        self._lsp.StartJob(self.starting_cmd, self.starting_cmd_argv)

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
        threading.Thread(target=self._get_workspace_config,
                         daemon=True).start()

        self.signature_help_triggerCharacters = []
        if 'signatureHelpProvider' in self.capabilities:
            temp = self.capabilities['signatureHelpProvider']
            if 'triggerCharacters' in temp:
                self.signature_help_triggerCharacters.extend(
                    temp['triggerCharacters'])

            if 'retriggerCharacters' in temp:
                self.signature_help_triggerCharacters.extend(
                    temp['retriggerCharacters'])

        self._init_semantic()

        self._lsp.initialized()

    def _get_format_config(self):
        self.engine_format_setting = utils.GetEngineConfig(
            self.engine_name, 'lsp_formatting')
        if self.engine_format_setting == None:
            self.engine_format_setting = utils.GetEngineConfig(
                'GLOBAL_SETTING', 'lsp_formatting')

    def _get_timeout(self):
        self.lsp_timeout = utils.GetEngineConfig(self.engine_name,
                                                 'lsp_timeout')
        if self.lsp_timeout == None:
            self.lsp_timeout = utils.GetEngineConfig('ECY', 'lsp_timeout')

        return self.lsp_timeout

    def _init_semantic(self):
        if 'semanticTokensProvider' not in self.capabilities:
            return

        self.semantic_color = utils.GetEngineConfig(self.engine_name,
                                                    'semantic_color')

        logger.debug(self.semantic_color)

        if type(self.semantic_color) is not list:
            self.semantic_color = []

        semanticTokensProvider = self.capabilities['semanticTokensProvider']
        self.is_support_full = False
        self.is_support_delta = False
        self.is_support_range = False

        if 'full' in semanticTokensProvider:
            if type(semanticTokensProvider['full']) is bool:
                self.is_support_full = semanticTokensProvider['full']
            else:
                self.is_support_full = True

        if 'range' in semanticTokensProvider:
            if type(semanticTokensProvider['range']) is bool:
                self.is_support_range = semanticTokensProvider['range']
            else:
                self.is_support_range = True

        if not self.is_support_full:
            return
        if type(semanticTokensProvider['full']) is not dict:
            return
        if 'delta' in semanticTokensProvider['full']:
            self.is_support_delta = semanticTokensProvider['full']['delta']

    def _handle_edit(self):
        while True:
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

    def _show_not_support_msg(self, features):
        self._show_msg("%s is not supported." % features)

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
        self.GetCodeLens(context)
        self.DocumentLink(context)
        self.semanticTokens(context)

    def OnSave(self, context):
        if 'textDocumentSync' not in self.capabilities:
            return
        if type(self.capabilities['textDocumentSync']) is not dict:
            return
        if 'save' not in self.capabilities[
                'textDocumentSync'] or not self.capabilities[
                    'textDocumentSync']['save']:
            return
        params = context['params']
        path = params['buffer_path']
        uri = self._lsp.PathToUri(path)
        version = context['params']['buffer_id']
        self._lsp.didSave(uri, version)

    def DocumentLink(self, context):
        if 'documentLinkProvider' not in self.capabilities or not self.enabled_document_link:
            return
        params = context['params']
        path = params['buffer_path']
        uri = self._lsp.PathToUri(path)
        res = self._lsp.documentLink(uri).GetResponse()
        res = res['result']

        if 'error' in res:
            self._show_msg(res['error']['message'])
            return

        if res is None:
            return

        for item in res:
            if 'target' in item:
                item['target'] = {'uri': item['target']}
                item['target']['path'] = self._lsp.UriToPath(
                    item['target']['uri'])

        res = {'res': res}
        res['buffer_path'] = path
        res['buffer_id'] = params['buffer_id']

        rpc.DoCall('ECY#document_link#Do', [res])

    def DocumentLinkResolve(self, context):
        if 'documentLinkProvider' not in self.capabilities or not self.enabled_document_link:
            return
        if self.capabilities[
                'documentLinkProvider'] is not dict or 'resolveProvider' in self.capabilities[
                    'documentLinkProvider']:
            return

        params = context['params']
        DocumentLink = params['DocumentLink']
        res = self._lsp.documentLinkResolve(DocumentLink).GetResponse()
        res = res['result']
        # TODO

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
        params = context['params']
        if params['change_mode'] == 'n':  # normal mode
            self.GetCodeLens(context)
            self.DocumentLink(context)
            self.semanticTokens(context)

    def SelectionRange(self, context):
        if 'selectionRangeProvider' not in self.capabilities:
            self._show_not_support_msg('SelectionRange')
            return

        params = context['params']
        path = params['buffer_path']
        uri = self._lsp.PathToUri(path)
        start_position = params['buffer_position']
        position = {
            'line': start_position['line'],
            'character': start_position['colum']
        }

        res = self._lsp.selectionRange(position, uri).GetResponse()
        res = res['result']

        if res is not None:
            res = res[0]
            res['path'] = path
            rpc.DoCall('ECY#selete_range#Do', [res])

    def FoldingRange(self, context):
        if 'foldingRangeProvider' not in self.capabilities:
            self._show_not_support_msg('FoldingRange')
            return

        params = context['params']
        path = params['buffer_path']
        start_position = params['buffer_position']
        is_current_line = params['is_current_line']
        uri = self._lsp.PathToUri(path)
        res = self._lsp.foldingRange(uri).GetResponse()
        res = res['result']

        if res is None:
            self._show_msg('Nothing to fold.')
            return

        i = 0
        if is_current_line:
            for item in res:
                if item['startLine'] <= start_position['line'] and item[
                        'endLine'] >= start_position['line']:
                    break
                i += 1

        res = {'res': res}
        res['path'] = path
        res['is_current_line'] = is_current_line
        res['buffer_position'] = start_position
        res['seleting_folding_range'] = i

        rpc.DoCall('ECY#folding_range#Do', [res])

    def OnWorkSpaceSymbol(self, context):
        if 'workspaceSymbolProvider' not in self.capabilities:
            self._show_not_support_msg('OnWorkSpaceSymbol')
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
            self._show_not_support_msg('OnDocumentSymbol')
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
            self._show_not_support_msg('OnTypeFormatting')
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
            self._show_not_support_msg('Format')
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

        activeSignature = 0
        default_active_param = 0
        if 'activeSignature' in res:
            activeSignature = res['activeSignature']
        if 'activeParameter' in res:
            default_active_param = res['activeParameter']

        to_show = []
        i = 0
        for SignatureHelp in res['signatures']:
            line = ''
            # if i == activeSignature:
            #     line = '=> '
            label = SignatureHelp['label']
            line += label

            if 'activeParameter' in SignatureHelp:
                active_param = SignatureHelp['activeParameter']
            else:
                active_param = default_active_param

            if 'parameters' in SignatureHelp and active_param < len(
                    SignatureHelp['parameters']):
                param_label = SignatureHelp['parameters'][active_param][
                    'label']
                start = label.find(param_label)
                str_len = len(param_label)
                SignatureHelp['start'] = start
                SignatureHelp['str_len'] = str_len

            to_show.append(line)
            i += 1

        document = []

        selecting_signature = res['signatures'][activeSignature]

        if 'documentation' in selecting_signature:
            document.extend(
                self._format_markupContent(
                    selecting_signature['documentation']))

        if 'activeParameter' in selecting_signature:
            active_param = selecting_signature['activeParameter']
        else:
            active_param = default_active_param

        if 'parameters' in selecting_signature and active_param < len(
                selecting_signature['parameters']):
            selecting_parameters = selecting_signature['parameters'][
                active_param]
            if 'documentation' in selecting_parameters:
                document.extend(selecting_parameters['documentation'])

        if len(document) != 0:
            to_show.append('--------')
            to_show.extend(document)
        res['to_show'] = to_show
        res['activeSignature'] = activeSignature

        if len(res) != 0:
            rpc.DoCall('ECY#signature_help#Show', [res])

    def OnInsertLeave(self, context):
        self.completion_position_cache = {}
        self.completion_isInCompleted = False
        self.GetCodeLens(context)
        self.DocumentLink(context)
        self.semanticTokens(context)

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

        rpc.DoCall('ECY#preview_windows#Show', [results_format])

    def OnCompletion(self, context):
        if 'completionProvider' not in self.capabilities:
            return

        self.trigger_key = []
        if 'triggerCharacters' in self.capabilities['completionProvider']:
            for item in self.capabilities['completionProvider'][
                    'triggerCharacters']:
                if item == ' ':
                    continue
                self.trigger_key.append(item)

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
            # TODO
            break
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

    def _to_ECY_format(self, context):
        if context is None:
            return  # server not supports.

        show_list = []
        for item in context['show_list']:
            results_format = {
                'abbr': '',
                'word': '',
                'kind': '',
                'menu': '',
                'info': '',
                'user_data': ''
            }

            item_name = item['label']
            results_format['abbr'] = item_name
            results_format['word'] = item_name

            if 'kind' in item:
                results_format['kind'] = self._lsp.GetKindNameByNumber(
                    item['kind'])
            else:
                results_format['kind'] = 'Unkonw'

            menu = []
            if 'detail' in item:
                menu = item['detail'].split('\n')

            if 'tags' in item:
                for tag in item['tags']:
                    if tag == 1:
                        menu.append('Deprecated')
            elif 'deprecated' in item:
                # @deprecated Use `tags` instead if supported.
                menu.append('Deprecated')

            results_format['menu'] = " ".join(menu)

            insertTextFormat = 0
            if 'insertTextFormat' in item:
                insertTextFormat = item['insertTextFormat']

            if insertTextFormat == 2:
                results_format['kind'] += '~'

            # When an edit is provided the value of `insertText` is ignored.
            word = ''
            if 'textEdit' in item:
                word = item['textEdit']['newText']
            elif 'insertText' in item:
                word = item['insertText']

            if word != '':
                if insertTextFormat == 2:
                    results_format['snippet'] = word
                else:
                    results_format['word'] = word

            document = []
            if 'documentation' in item:
                document.extend(
                    self._format_markupContent(item['documentation']))
            results_format['info'] = '\n'.join(document)

            if 'completion_text_edit' in item and False:
                results_format['completion_text_edit'] = item[
                    'completion_text_edit']
                results_format['word'] = item['textEdit']['newText']

            show_list.append(results_format)
        context['origin_list'] = context['show_list']
        context['show_list'] = show_list
        return context

    def ExecuteCommand(self, context):
        if 'executeCommandProvider' not in self.capabilities:
            self._show_not_support_msg('executeCommand')
            return
        params = context['params']
        cmd_name = params['cmd_name']
        cmd_list = self.capabilities['executeCommandProvider']['commands']

        if cmd_name not in cmd_list:
            self._show_msg("'%s' not found.\n %s" % (cmd_name, str(cmd_list)))
            return
        cmd_params = params['cmd_params']
        self._lsp.executeCommand(cmd_name, arguments=cmd_params)
        rpc.DoCall('ECY#code_lens#Do', [res])

    def GetExecuteCommand(self, context):
        if 'executeCommandProvider' not in self.capabilities:
            self._show_not_support_msg('executeCommand')
            return

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
                self._lsp._build_response(None, jobs['id'])
            except Exception as e:
                logger.exception(e)

    def _get_workspace_config(self):
        while True:
            try:
                jobs = self._lsp.GetRequestOrNotification(
                    'workspace/configuration')
                logger.debug(jobs)
                params = jobs['params']
                res = {}
                for item in params:
                    res[item] = utils.GetEngineConfig(self.engine_name, item)
                self._lsp._build_response(res, jobs['id'])
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

    def _build_token_modifiers(self, modifiers):
        str_bin = format(modifiers, 'b')
        tokenModifiers = self.capabilities['semanticTokensProvider']['legend'][
            'tokenModifiers']

        res = []
        i = len(str_bin)
        for item in str_bin:
            i -= 1
            if item == '0':
                continue
            res.append(tokenModifiers[i])

        return res

    def _build_token_type(self, tokenType):
        tokenType_list = self.capabilities['semanticTokensProvider']['legend'][
            'tokenTypes']

        return tokenType_list[tokenType]

    def _build_semantic(self, data):
        res = []
        item = len(data) / 5
        i = 0
        colum_count = 0
        line_count = 0
        while i < item:
            j = i * 5
            line = data[j]
            line_count += line
            colum = data[j + 1]
            if line == 0:
                colum_count += colum
                colum = colum_count
            else:
                colum_count = colum

            tokenType = self._build_token_type(data[j + 3])
            tokenModifiers = self._build_token_modifiers(data[j + 4])

            for color_item in self.semantic_color:
                is_defined = True
                for color in color_item[0]:
                    if tokenType != color and color not in tokenModifiers:
                        is_defined = False
                        break

                if is_defined:
                    res.append({
                        'line': line_count,
                        'start_colum': colum,
                        'end_colum': data[j + 2] + colum,
                        'tokenType': tokenType,
                        'color': color_item[1],
                        'tokenModifiers': tokenModifiers,
                    })
                    break
            i += 1
        return res

    def semanticTokens(self, context):
        if 'semanticTokensProvider' not in self.capabilities or self.semantic_color == []:
            return

        params = context['params']
        path = params['buffer_path']
        uri = self._lsp.PathToUri(path)

        previousResultId = None
        if uri in self.semantic_info and self.is_support_delta and False:
            # TODO: delta not support yet
            send_type = 'full_delta'
            previousResultId = self.semantic_info[uri]['resultId']
        elif self.is_support_range:
            send_type = 'range'
        elif self.is_support_full:
            send_type = 'full'
        else:
            return

        res = self._lsp.semanticTokens(
            uri, send_type, previousResultId=previousResultId).GetResponse()

        if 'error' in res:
            self._show_msg(res['error']['message'])
            return

        res = res['result']
        if res is None:
            return

        is_full = False
        if send_type == 'full':
            is_full = True
        elif send_type == 'full_delta':
            if 'edits' not in res:
                is_full = True

        if is_full:
            temp = {'data': self._build_semantic(res['data']), 'path': path}
            res['builded_cache'] = temp
            self.semantic_info[uri] = res
            rpc.DoCall('ECY#semantic_tokens#Update', [temp])

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

    def _goto_response(self, res, is_preview=False):
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

        if is_preview:
            rpc.DoCall('ECY#goto#Preview', [res])
        else:
            rpc.DoCall('ECY#goto#Open', [res])

    def GotoDefinition(self, context):
        if 'definitionProvider' not in self.capabilities:
            self._show_not_support_msg('GotoDefinition')
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
        self._goto_response(res, params['is_preview'])

    def GotoTypeDefinition(self, context):
        if 'typeDefinitionProvider' not in self.capabilities:
            self._show_not_support_msg('GotoTypeDefinition')
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
        self._goto_response(res, params['is_preview'])

    def GotoImplementation(self, context):
        if 'implementationProvider' not in self.capabilities:
            self._show_not_support_msg('GotoImplementation')
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
        self._goto_response(res, params['is_preview'])

    def GotoDeclaration(self, context):
        if 'declarationProvider' not in self.capabilities:
            self._show_not_support_msg('GotoDeclaration')
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

        self._goto_response(res, params['is_preview'])

    def OnHover(self, context):
        if 'hoverProvider' not in self.capabilities:
            self._show_not_support_msg('Hover')
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
        """return list
        """
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
            self._show_not_support_msg('FindReferences')
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
        if 'codeLensProvider' not in self.capabilities or not self.enabled_code_lens:
            return
        params = context['params']
        path = params['buffer_path']
        uri = self._lsp.PathToUri(path)
        res = self._lsp.codeLens(uri).GetResponse()

        if 'error' in res:
            self._show_msg(res['error']['message'])
            return
        res = res['result']

        res = {'res': res, 'path': path}
        rpc.DoCall('ECY#code_lens#Do', [res])

    def PrepareCallHierarchy(self, context):
        params = context['params']
        if 'callHierarchyProvider' not in self.capabilities:
            self._show_not_support_msg('PrepareCallHierarchy')
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
            self._show_not_support_msg('Rename')
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
