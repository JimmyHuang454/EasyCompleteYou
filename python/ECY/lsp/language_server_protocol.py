# Author: Jimmy Huang (1902161621@qq.com)
# License: WTFPL

import json
import sys
import threading
import queue
import os
from urllib.parse import urljoin
from urllib.request import pathname2url
from urllib.parse import urlparse
from urllib.request import url2pathname

from ECY.debug import logger
from ECY.lsp import symbol_kind
from ECY.lsp import completion_kind

BASE_DIR = os.path.abspath(os.path.dirname(__file__))
sys.path.append(os.path.dirname(BASE_DIR) + '/engines')

# local lib
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
        if type(timeout) is int and timeout != -1 and timeout != 0:
            try:
                self.response_queue = queue.Queue(timeout)
            except Exception as e:
                self.response_queue = None  # importance
                raise e
        else:  # without timeout that is means keep runing forever.
            self.response_queue = queue.Queue()
        if callback is not None:
            self.callback = callback
            self.callback_additional_data = callback_additional_data
            threading.Thread(target=self._callback_thread).start()
            return self  # are not blocked
        return self.response_queue.get()

    def _callback_thread(self):
        try:
            res = self.response_queue.get()
            res['callback_additional_data'] = self.callback_additional_data
            self.callback(res)
        except Exception as e:
            logger.exception(e)

    def ResponseArrive(self, response):
        if self.response_queue is None:
            # user have no intention to get request's response.
            return

        logger.debug("<---" + str(response))
        self.response_queue.put(response)


class LSP(conec.Operate):
    def __init__(self, timeout=None):
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
                      message.encode(encoding="utf-8"))
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
        self.SendData(self.server_id, message.encode(encoding="utf-8"))
        return True

    def BuildCapabilities(self):
        with open(BASE_DIR + '/capability.json', encoding='utf-8') as f:
            content = f.read()
        content = json.loads(content)
        return content

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

    def completionItem_resolve(self, completion_item):
        return self._build_send(completion_item, 'completionItem/resolve')

    def _get_progress_token(self):
        self.workDoneToken_id += 1
        return self.workDoneToken_id

    def _get_workdone_token(self):
        self.workDoneToken_id += 1
        return self.workDoneToken_id

    def prepareRename(self,
                      uri,
                      languageId,
                      text,
                      version,
                      position,
                      new_name,
                      workDoneToken=None):

        if workDoneToken is None:
            workDoneToken = self._get_workdone_token()

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
            'workDoneToken': workDoneToken,
            'newName': new_name
        }
        return self._build_send(params, 'textDocument/rename')

    def rename(self,
               uri,
               languageId,
               text,
               version,
               position,
               new_name,
               workDoneToken=None):

        if workDoneToken is None:
            workDoneToken = self._get_workdone_token()

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
            'workDoneToken': workDoneToken,
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

    def codeLens(self, uri, workDoneToken=None, ProgressToken=None):
        if workDoneToken is None:
            workDoneToken = self._get_workdone_token()
        if ProgressToken is None:
            ProgressToken = self._get_progress_token()

        params = {
            'workDoneToken': workDoneToken,
            'partialResultToken': ProgressToken,
            'textDocument': {
                'uri': uri
            }
        }
        return self._build_send(params, 'textDocument/codeLens')

    def onTypeFormatting(self,
                         uri,
                         line,
                         colum,
                         strings,
                         opts,
                         path_type='uri'):
        params = self.TextDocumentPositionParams(uri,
                                                 line,
                                                 colum,
                                                 path_type=path_type)
        params['ch'] = strings
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

    def codeAction(self,
                   uri,
                   start_position,
                   end_position,
                   diagnostic=[],
                   workDoneToken=None,
                   ProgressToken=None):

        if workDoneToken is None:
            workDoneToken = self._get_workdone_token()
        if ProgressToken is None:
            ProgressToken = self._get_progress_token()

        params = {
            'workDoneToken': workDoneToken,
            'partialResultToken': ProgressToken,
            'range': self.Range(start_position, end_position),
            'context': {
                'diagnostics': diagnostic
            },
            'textDocument': {
                'uri': uri
            }
        }
        return self._build_send(params, 'textDocument/codeAction')

    def executeCommand(self, command, workDoneToken=None, arguments=[]):
        if workDoneToken is None:
            self.workDoneToken_id += 1
            workDoneToken = self.workDoneToken_id

        params = {'workDoneToken': workDoneToken, 'command': command}

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

    def workspaceSymbos(self, query=""):
        # query == "" means returning all symbols.
        # few of Server supports this feature.
        params = {'query': query}
        return self._build_send(params, 'workspace/symbol')

    def signatureHelp(self, uri, position, ProgressToken=None, context=None):
        if ProgressToken is None:
            ProgressToken = self._get_progress_token()

        # position = {'line': 0 , 'character': 0}
        textDocument = {'uri': uri}
        params = {
            'textDocument': textDocument,
            'position': position,
            'progressToken': ProgressToken
        }

        if context is not None:
            params['context'] = context
        return self._build_send(params, 'textDocument/signatureHelp')

    def references(self,
                   position,
                   uri,
                   includeDeclaration=True,
                   query="",
                   ProgressToken="",
                   partialProgressToken=""):
        # ProgressToken = number | string
        params = {
            'textDocument': {
                'uri': uri
            },
            'context': {
                'includeDeclaration': includeDeclaration
            },
            'workDoneToken': ProgressToken,
            'partialResultToken': partialProgressToken,
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

    def PathToUri(self, file_path):
        return urljoin('file:', pathname2url(file_path))

    def UriToPath(self, uri):
        if self._current_system() == 'Windows':
            # url2pathname does not understand %3A (VS Code's encoding forced on all servers :/)
            file_path = url2pathname(urlparse(uri).path).strip('\\')
            if file_path[0].islower():
                file_path = file_path[0].upper() + file_path[1:]
            return file_path
        else:
            return url2pathname(urlparse(uri).path)

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

    def GetMessageType(self, kindNr):
        # {{{
        if kindNr == 1:
            return 'Error'
        if kindNr == 2:
            return 'Warning'
        if kindNr == 3:
            return 'Info'
        if kindNr == 4:
            return 'Log'


# }}}

    def GetKindNameByNumber(self, kindNr):
        if kindNr not in completion_kind.COMPLETION_KIND:
            return "Unkonw"
        return completion_kind.COMPLETION_KIND[kindNr]

    def GetSymbolsKindByNumber(self, kindNr):
        if kindNr not in symbol_kind.SYMBOL_KIND:
            return "Unkonw"
        return symbol_kind.SYMBOL_KIND[kindNr]

    def _current_system(self):
        temp = sys.platform
        if temp == 'win32':
            return 'Windows'
        if temp == 'cygwin':
            return 'Cygwin'
        if temp == 'darwin':
            return 'Mac'
        return 'Linux'
