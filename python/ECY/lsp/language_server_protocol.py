# Author: Jimmy Huang (1902161621@qq.com)
# License: WTFPL

import json
import sys
import threading
import queue
import os
from urllib.parse import urljoin
from urllib.parse import quote
from urllib.parse import unquote
from urllib.parse import urlparse
from urllib.request import pathname2url
from urllib.request import url2pathname

from ECY.debug import logger
from ECY import utils
from ECY.lsp import symbol_kind
from ECY.lsp import completion_kind
from ECY.lsp import capability
from ECY.lsp import uri as uri_op
from ECY.lsp import stand_IO_connection as conec


class LSPRequest(object):
    """
    """
    def __init__(self, method_name, ids, timeout=None):
        """
        """
        self.Method = method_name
        self.ID = ids
        self.response_queue = None
        self.callback = None
        self.callback_additional_data = {}
        self.default_timeout = timeout

    def GetResponse(self,
                    timeout=None,
                    callback=None,
                    callback_additional_data={}):
        """ if user want to run with no timeout so set timeout to -1 or 0
        """
        if timeout is None and self.default_timeout is not None:
            timeout = self.default_timeout
        self.response_queue = queue.Queue()

        if callback is not None:
            self.callback = callback
            self.callback_additional_data = callback_additional_data
            threading.Thread(target=self._callback_thread).start()
            return self  # is not blocked

        # block here.
        if timeout is None:
            # without timeout that is means keep runing forever.
            return self.response_queue.get()
        else:
            return self.response_queue.get(timeout=timeout)

    def _callback_thread(self):
        try:
            res = self.response_queue.get()
            res['callback_additional_data'] = self.callback_additional_data
            self.Callback(res)
        except Exception as e:
            logger.exception(e)
            self.Callback(e)

    def Callback(self, res):
        if self.callback is not None:
            self.callback(res)

    def ResponseArrive(self, response):
        if self.response_queue is None:
            # user have no intention to get request's response.
            return

        logger.debug("<---" + str(response))
        self.response_queue.put(response)


class LSP(conec.Operate):
    def __init__(self, timeout=None):
        self.encoding = 'utf-8'
        self._id = 0
        self.server_id = -1
        self._queue_dict = {}
        self._waitting_response = {}
        self.workDoneToken_id = 0
        self.workDoneToken = 0
        self.id_lock = threading.Lock()
        super().__init__()
        threading.Thread(target=self._classify_response, daemon=True).start()
        self.queue_maxsize = 20
        self._using_server_id = None
        self.default_timeout = timeout

    def Debug(self, msg):
        logger.info(msg)

    def _classify_response(self):
        while 1:
            todo = self.GetTodo()
            todo = json.loads(todo['data'])
            if 'id' not in todo:
                # a notification send from server
                todo['ECY_type'] = 'notification'
                self.Debug("<---" + str(todo))
                self._add_queue(todo['method'], todo)
            elif todo['id'] in self._waitting_response and 'method' not in todo:
                # a response
                ids = todo['id']
                todo['ECY_type'] = 'response'
                self._waitting_response[ids].ResponseArrive(todo)
                del self._waitting_response[ids]
            else:
                # a request that send from the server
                todo['ECY_type'] = 'request'
                self._add_queue(todo['method'], todo)

    def GetServerStatus_(self):
        return self.GetServerStatus(self.server_id)

    def GetRequestOrNotification(self, _method_name, timeout=None):
        if _method_name not in self._queue_dict:
            # new
            self._queue_dict[_method_name] = queue.Queue(
                maxsize=self.queue_maxsize)
        queue_obj = None
        try:
            if timeout == -1 or timeout == None or timeout == 0:
                # never timeout
                queue_obj = self._queue_dict[_method_name].get()
            else:
                queue_obj = self._queue_dict[_method_name].get(timeout=timeout)
        except:
            del self._queue_dict[_method_name]
        if queue_obj is None:
            raise ValueError('queue time out.')
        return queue_obj

    def _add_queue(self, method_name, _todo):
        if method_name is None:
            return

        if method_name in self._queue_dict:
            obj_ = self._queue_dict[method_name]
            obj_.put(_todo)
            return self._queue_dict[method_name]

        self.Debug('Abandomed ' + method_name)
        self.Debug(_todo)

    def ChangeUsingServerID(self, id_nr):
        if id_nr > self.server_count:
            raise ValueError('have no such a server process.')
        self._using_server_id = id_nr

    def GetUsingServerID(self):
        if self._using_server_id is None:
            return self.server_id
        return self._using_server_id

    def _build_send(self, params, method, isNotification=False):
        """build request format and send it to server as request
           or notification.
        """
        if self.server_id <= 0:
            raise ValueError(
                'E002: you have to send a initialize request first.')
        send = {'jsonrpc': '2.0', 'method': method, 'params': params}

        self.id_lock.acquire()
        self._id += 1
        if not isNotification:
            # id_text       = "ECY_"+str(self._id)
            send['id'] = self._id
            if params is not None:
                params['workDoneToken'] = self._get_workdone_token()
        context = LSPRequest(method, self._id, timeout=self.default_timeout)
        self._waitting_response[self._id] = context
        self.id_lock.release()

        send = json.dumps(send)
        context_lenght = len(send)
        if method not in ['textDocument/didOpen', 'textDocument/didChange']:
            self.Debug("--->" + send)
        message = ("Content-Length: {}\r\n\r\n"
                   "{}".format(context_lenght, send))
        self.SendData(self.GetUsingServerID(),
                      message.encode(encoding=self.encoding))
        return context

    def _build_response(self, results, ids, error=None):
        if self.server_id <= 0:
            # raise an erro:
            # return 'E002: you have to send a initialize request first.'
            return None
        context = {'jsonrpc': '2.0', 'result': results, 'id': ids}
        if error is not None:
            context['error'] = error
        context = json.dumps(context)
        context_lenght = len(context)
        self.Debug("--->" + context)
        message = ("Content-Length: {}\r\n\r\n"
                   "{}".format(context_lenght, context))
        self.SendData(self.server_id, message.encode(encoding=self.encoding))
        return True

    def BuildCapabilities(self):
        return capability.CAPABILITY

    def initialize(self,
                   processId=None,
                   rootUri=None,
                   rootPath=None,
                   initializationOptions=None,
                   trace='off',
                   clientInfo=None,
                   workspaceFolders=None,
                   capabilities=None):

        if self.server_count == 0:
            return 'E001:you have to start a server first.'
        else:
            self.server_id = self.server_count
        if capabilities is None:
            capabilities = self.BuildCapabilities()
        if processId is None:
            processId = os.getpid()

        if clientInfo is None:
            clientInfo = {'name': 'ECY', 'version': "1"}

        params = {
            'processId': processId,
            'rootUri': rootUri,
            'initializationOptions': initializationOptions,
            'workspaceFolders': workspaceFolders,
            'capabilities': capabilities,
            'rootPath': rootPath,
            'clientInfo': clientInfo,
            'trace': trace
        }
        return self._build_send(params, 'initialize')

    def didChangeConfiguration(self, setting):
        params = {'settings': setting}
        return self._build_send(params,
                                'workspace/didChangeConfiguration',
                                isNotification=True)

    def didChangeWorkspaceFolders(self, add_workspace=[], remove_workspace=[]):
        # add_workspace = {'uri': 'xx', 'name': 'yyy'}
        if add_workspace == [] and remove_workspace == []:
            return

        params = {
            'event': {
                'added': add_workspace,
                'removed': remove_workspace
            }
        }
        return self._build_send(params,
                                'workspace/didChangeWorkspaceFolders',
                                isNotification=True)

    def initialized(self):
        return self._build_send({}, 'initialized', isNotification=True)

    def configuration_response(self, ids, results=[]):
        """ workspace/configuration, a response send to Server.
        """
        return self._build_response(results, ids)

    def wordDoneProgress_response(self, ids):
        return self._build_response(None, ids)

    def applyEdit_response(self,
                           ids,
                           applied,
                           failureReason="",
                           failedChange=0):

        result = {'applied': applied}
        if failureReason != "":
            result['failureReason'] = failureReason
        if failedChange != 0:
            result['failedChange'] = failedChange
        return self._build_response(result, ids)

    def didopen(self, uri, languageId, text, version=None):
        textDocument = {
            'uri': uri,
            'languageId': languageId,
            'text': text,
            'version': version
        }
        params = {'textDocument': textDocument}
        return self._build_send(params,
                                'textDocument/didOpen',
                                isNotification=True)

    def didchange(self,
                  uri,
                  text,
                  version=None,
                  range_=None,
                  rangLength=None,
                  wantDiagnostics=True):
        # wantDiagnostics is only for clangd

        textDocument = {'version': version, 'uri': uri}
        params = {'textDocument': textDocument}
        if range_ is not None:
            TextDocumentContentChangeEvent = {
                'range': range_,
                'rangLength': rangLength,
                'text': text
            }
        else:
            TextDocumentContentChangeEvent = {'text': text}
        params = {
            'textDocument': textDocument,
            'wantDiagnostics': wantDiagnostics,
            'contentChanges': [TextDocumentContentChangeEvent]
        }
        return self._build_send(params,
                                'textDocument/didChange',
                                isNotification=True)

    def didSave(self, uri, version, text=None):
        textDocument = {'version': version, 'uri': uri}
        params = {'textDocument': textDocument}
        if text is not None:
            params['text'] = text
        return self._build_send(params,
                                'textDocument/didSave',
                                isNotification=True)

    def completionItem_resolve(self, completion_item):
        return self._build_send(completion_item, 'completionItem/resolve')

    def _get_progress_token(self):
        self.workDoneToken_id += 1
        return self.workDoneToken_id

    def _get_workdone_token(self):
        self.workDoneToken_id += 1
        return "ECY_workDoneToken-" + str(self.workDoneToken_id)

    def prepareRename(self, uri, languageId, text, version, position,
                      new_name):

        if new_name == '':
            raise ValueError("new_name can not be None")

        textDocument = {
            'uri': uri,
            'languageId': languageId,
            'text': text,
            'version': version
        }
        params = {
            'textDocument': textDocument,
            'position': position,
            'newName': new_name
        }
        return self._build_send(params, 'textDocument/rename')

    def rename(self, uri, languageId, text, version, position, new_name):

        if new_name == '':
            raise ValueError("new_name can not be None")

        textDocument = {
            'uri': uri,
            'languageId': languageId,
            'text': text,
            'version': version
        }
        params = {
            'textDocument': textDocument,
            'position': position,
            'newName': new_name
        }
        return self._build_send(params, 'textDocument/rename')

    def FormattingOptions(self, context):
        opts = {
            'tabSize': tabSize,
            'insertSpaces': insertSpaces,
            'insertFinalNewline': insertFinalNewline,
            'trimFinalNewlines': trimFinalNewlines,
            'trimTrailingWhitespace': trimTrailingWhitespace
        }
        return opts

    def formatting(self, uri, opts):
        params = {
            'textDocument': self.TextDocumentIdentifier(uri),
            'options': opts
        }
        return self._build_send(params, 'textDocument/formatting')

    def codeLens(self, uri):
        params = {'textDocument': {'uri': uri}}
        return self._build_send(params, 'textDocument/codeLens')

    def onTypeFormatting(self,
                         uri,
                         line,
                         colum,
                         ch,
                         opts,
                         path_type='uri'):
        params = self.TextDocumentPositionParams(uri,
                                                 line,
                                                 colum,
                                                 path_type=path_type)
        params['ch'] = ch
        params['options'] = opts
        return self._build_send(params, 'textDocument/onTypeFormatting')

    def Range(self, start_position, end_position):
        return {'start': start_position, 'end': end_position}

    def OptionalVersionedTextDocumentIdentifier(self,
                                                path,
                                                path_type='uri',
                                                ids=None):
        temp = self.TextDocumentIdentifier(path, path_type=path_type)
        temp['version'] = ids
        return temp

    def TextDocumentIdentifier(self, uri, path_type='uri'):
        if path_type != 'uri':
            uri = self.PathToUri(uri)
        return {'uri': uri}

    def Position(self, line, colum):
        return {'line': line, 'character': colum}

    def TextDocumentPositionParams(self, uri, line, colum, path_type='uri'):
        return {
            'textDocument': self.TextDocumentIdentifier(uri,
                                                        path_type=path_type),
            'position': self.Position(line, colum)
        }

    def codeAction(self, uri, start_position, end_position, diagnostic=[]):

        params = {
            'range': self.Range(start_position, end_position),
            'context': {
                'diagnostics': diagnostic
            },
            'textDocument': {
                'uri': uri
            }
        }
        return self._build_send(params, 'textDocument/codeAction')

    def executeCommand(self, command, arguments=[]):

        params = {'command': command}

        if type(arguments) is not list:
            raise ValueError("type of arguments must be list.")

        if arguments != []:
            params['arguments'] = arguments

        return self._build_send(params, 'workspace/executeCommand')

    def completion(self, uri, position, triggerKind=1, triggerCharacter=None):
        TextDocumentIdentifier = self.TextDocumentIdentifier(uri)

        CompletionContext = {'triggerKind': triggerKind}
        if triggerCharacter is not None:
            CompletionContext['triggerCharacters'] = triggerCharacter

        params = {
            'context': CompletionContext,
            'textDocument': TextDocumentIdentifier,
            'position': position
        }
        return self._build_send(params, 'textDocument/completion')

    def hover(self, position, uri):
        params = {'textDocument': {'uri': uri}, 'position': position}
        return self._build_send(params, 'textDocument/hover')

    def documentSymbos(self, uri):
        params = {'textDocument': {'uri': uri}}
        return self._build_send(params, 'textDocument/documentSymbol')

    def semanticTokens(self, uri, ranges, previousResultId=None):
        params = {'textDocument': self.TextDocumentIdentifier(uri)}
        if ranges == 'full':
            event = 'textDocument/semanticTokens/full'
        elif ranges == 'full_delta':
            # previousResultId can not be None
            params['previousResultId'] = previousResultId
            event = 'textDocument/semanticTokens/full/delta'
        elif type(ranges) is dict:
            params['range'] = ranges
            event = 'textDocument/semanticTokens/range'
        else:
            params = None
            event = 'workspace/semanticTokens/refresh'
        return self._build_send(params, event)

    def workspaceSymbos(self, query=""):
        # query == "" means returning all symbols.
        # few of Server supports this feature.
        params = {'query': query}
        return self._build_send(params, 'workspace/symbol')

    def signatureHelp(self, uri, position, context=None):
        # position = {'line': 0 , 'character': 0}
        textDocument = {'uri': uri}
        params = {
            'textDocument': textDocument,
            'position': position,
        }

        if context is not None:
            params['context'] = context
        return self._build_send(params, 'textDocument/signatureHelp')

    def references(self, position, uri, includeDeclaration=True, query=""):
        params = {
            'textDocument': {
                'uri': uri
            },
            'context': {
                'includeDeclaration': includeDeclaration
            },
            'position': position
        }
        return self._build_send(params, 'textDocument/references')

    def definition(self, position, uri):
        params = {'textDocument': {'uri': uri}, 'position': position}
        return self._build_send(params, 'textDocument/definition')

    def typeDefinition(self, position, uri):
        params = {'textDocument': {'uri': uri}, 'position': position}
        return self._build_send(params, 'textDocument/typeDefinition')

    def implementation(self, position, uri):
        params = {'textDocument': {'uri': uri}, 'position': position}
        return self._build_send(params, 'textDocument/implementation')

    def declaration(self, position, uri):
        params = {'textDocument': {'uri': uri}, 'position': position}
        return self._build_send(params, 'textDocument/definition')

    def prepareCallHierarchy(self, position, uri):
        params = {'textDocument': {'uri': uri}, 'position': position}
        return self._build_send(params, 'textDocument/prepareCallHierarchy')

    def IncomingCallHierarchy(self, CallHierarchyItem):
        params = {'item': CallHierarchyItem}
        return self._build_send(params, 'callHierarchy/incomingCalls')

    def OutgoingCallHierarchy(self, CallHierarchyItem):
        params = {'item': CallHierarchyItem}
        return self._build_send(params, 'callHierarchy/outgoingCalls')

    def documentLink(self, uri):
        params = {'textDocument': {'uri': uri}}
        return self._build_send(params, 'textDocument/documentLink')

    def documentLinkResolve(self, DocumentLink):
        return self._build_send(DocumentLink, 'documentLink/resolve')

    def selectionRange(self, position, uri):
        params = {'textDocument': {'uri': uri}, 'positions': [position]}
        return self._build_send(params, 'textDocument/selectionRange')

    def foldingRange(self, uri):
        params = {'textDocument': {'uri': uri}}
        return self._build_send(params, 'textDocument/foldingRange')

    def PathToUri(self, file_path):
        return uri_op.from_fs_path(file_path)

    def UriToPath(self, input_uri):
        return uri_op.to_fs_path(input_uri)

    def GetDiagnosticSeverity(self, kindNr):
        # {{{
        if kindNr == 1:
            return 'Error'
        if kindNr == 2:
            return 'Warning'
        if kindNr == 3:
            return 'Information'
        if kindNr == 4:
            return 'Hint'
        # }}}

    def GetKindNameByNumber(self, kindNr):
        if kindNr not in completion_kind.COMPLETION_KIND:
            return "Unkonw"
        return completion_kind.COMPLETION_KIND[kindNr]

    def GetSymbolsKindByNumber(self, kindNr):
        if kindNr not in symbol_kind.SYMBOL_KIND:
            return "Unkonw"
        return symbol_kind.SYMBOL_KIND[kindNr]
