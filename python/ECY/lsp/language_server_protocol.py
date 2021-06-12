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

BASE_DIR = os.path.abspath(os.path.dirname(__file__))
sys.path.append(os.path.dirname(BASE_DIR) + '/engines')

# local lib
from ECY.lsp import stand_IO_connection as conec


class LSPRequest(object):
    """
    """
    def __init__(self, method_name, ids):
        """
        """
        self.Method = method_name
        self.ID = ids
        self.response_queue = None
        self.callback = None
        self.callback_additional_data = {}

    def GetResponse(self,
                    timeout=None,
                    callback=None,
                    callback_additional_data={}):
        if type(timeout) is int and timeout != -1 and timeout != 0:
            try:
                self.response_queue = queue.Queue(timeout)
            except Exception as e:
                self.response_queue = None  # importance
                raise e
        else:
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
        self.response_queue.put(response)


class LSP(conec.Operate):
    def __init__(self):
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

    def Debug(self, msg):
        logger.info(msg)

    def _classify_response(self):
        while 1:
            todo = self.GetTodo()
            self.Debug("<---" + todo['data'])
            todo = json.loads(todo['data'])
            if 'id' not in todo:
                # a notification send from server
                todo['ECY_type'] = 'notification'
                self._add_queue(todo['method'], todo)
            elif todo['id'] in self._waitting_response and 'method' not in todo:
                # a response
                ids = todo['id']
                if ids not in self._waitting_response:
                    self.Debug("a response that can Not recognize")
                    continue
                todo['ECY_type'] = 'response'
                self._waitting_response[ids].ResponseArrive(todo)
                del self._waitting_response[ids]
            else:
                # a request that send from the server
                todo['ECY_type'] = 'request'
                self._add_queue(todo['method'], todo)

    def GetServerStatus_(self):
        return self.GetServerStatus(self.server_id)

    def GetRequestOrNotification(self, _method_name, timeout=5):
        if _method_name not in self._queue_dict:
            # new
            self._queue_dict[_method_name] = queue.Queue(
                maxsize=self.queue_maxsize)
        queue_obj = None
        try:
            if timeout == -1 or timeout == None:
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
        context = LSPRequest(method, self._id)
        self._waitting_response[self._id] = context
        self.id_lock.release()

        send = json.dumps(send)
        context_lenght = len(send)
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

    def formatting(self,
                   uri,
                   tabSize,
                   insertSpaces,
                   trimTrailingWhitespace=True,
                   insertFinalNewline=True,
                   trimFinalNewlines=True,
                   workDoneToken=None,
                   ProgressToken=None):
        if workDoneToken is None:
            workDoneToken = self._get_workdone_token()
        if ProgressToken is None:
            ProgressToken = self._get_progress_token()

        params = {
            'workDoneToken': workDoneToken,
            'partialResultToken': ProgressToken,
            'textDocument': self.TextDocumentIdentifier(uri)
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

    def Position(self, line, colum):
        return {'line': line, 'character': colum}

    def Range(self, start_position, end_position):
        return {'start': start_position, 'end': end_position}

    def OptionalVersionedTextDocumentIdentifier(self,
                                                path,
                                                path_type='uri',
                                                ids=None):
        temp = self.TextDocumentIdentifier(path, path_type=path_type)
        temp['version'] = ids
        return temp

    def TextDocumentIdentifier(self, path, path_type='uri'):
        if path_type != 'uri':
            uri = self.PathToUri(path)
        return {'uri': uri}

    def TextDocumentPositionParams(self, uri, line, colum):
        return {
            'textDocument': self.TextDocumentIdentifier(uri),
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
        TextDocumentIdentifier = {'uri': uri}

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
        # {{{ completion kind
        if kindNr == 1:
            return 'Text'
        if kindNr == 2:
            return 'Method'
        if kindNr == 3:
            return 'Function'
        if kindNr == 4:
            return 'Constructor'
        if kindNr == 5:
            return 'Field'
        if kindNr == 6:
            return 'Variable'
        if kindNr == 7:
            return 'Class'
        if kindNr == 8:
            return 'Interface'
        if kindNr == 9:
            return 'Module'
        if kindNr == 10:
            return 'Property'
        if kindNr == 11:
            return 'Unit'
        if kindNr == 12:
            return 'Value'
        if kindNr == 13:
            return 'Enum'
        if kindNr == 14:
            return 'Keyword'
        if kindNr == 15:
            return 'Snippet'
        if kindNr == 16:
            return 'Color'
        if kindNr == 17:
            return 'File'
        if kindNr == 18:
            return 'Reference'
        if kindNr == 19:
            return 'Folder'
        if kindNr == 20:
            return 'EnumMember'
        if kindNr == 21:
            return 'Constant'
        if kindNr == 22:
            return 'Struct'
        if kindNr == 23:
            return 'Event'
        if kindNr == 24:
            return 'Operator'
        if kindNr == 25:
            return 'TypeParameter'
        return 'Unkonw'  # }}}

    def GetSymbolsKindByNumber(self, kindNr):
        # {{{
        if kindNr == 1:
            return "File"
        if kindNr == 2:
            return "Module"
        if kindNr == 3:
            return "NameSpace"
        if kindNr == 4:
            return "Package"
        if kindNr == 5:
            return "Class"
        if kindNr == 6:
            return "Method"
        if kindNr == 7:
            return "Property"
        if kindNr == 8:
            return "Field"
        if kindNr == 9:
            return "Constructor"
        if kindNr == 10:
            return "Enum"
        if kindNr == 11:
            return "Interface"
        if kindNr == 12:
            return "Function"
        if kindNr == 13:
            return "Variable"
        if kindNr == 14:
            return "Constant"
        if kindNr == 15:
            return "String"
        if kindNr == 16:
            return "Number"
        if kindNr == 17:
            return "Boolean"
        if kindNr == 18:
            return "Array"
        if kindNr == 19:
            return "Object"
        if kindNr == 20:
            return "Key"
        if kindNr == 21:
            return "Null"
        if kindNr == 22:
            return "EnumMember"
        if kindNr == 23:
            return "Struct"
        if kindNr == 24:
            return "Event"
        if kindNr == 25:
            return "Operator"
        if kindNr == 26:
            return "TypeParameter"
        return 'Unkonw'


# }}}

    def _current_system(self):
        temp = sys.platform
        if temp == 'win32':
            return 'Windows'
        if temp == 'cygwin':
            return 'Cygwin'
        if temp == 'darwin':
            return 'Mac'
        return 'Linux'
