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
from loguru import logger

# local lib
from ECY.lsp import stand_IO_connection as conec


class LSP(conec.Operate):
    def __init__(self):
        self._id = 0
        self._lock = threading.Lock()
        self.server_id = -1
        self._queue_dict = {}
        self._waitting_response = {}
        self.workDoneToken_id = 0
        super().__init__()
        threading.Thread(target=self._classify_response, daemon=True).start()
        self._using_server_id = None

    def Debug(self, msg):
        logger.info(msg)

    def _classify_response(self):
        while 1:
            todo = self.GetTodo()
            debug = "<---" + todo['data']
            self.Debug(debug)
            todo = json.loads(todo['data'])
            if 'id' not in todo.keys():
                # a notification send from server
                self._add_queue(todo['method'], todo)
            else:
                if todo['id'] in self._waitting_response or\
                        'method' not in todo.keys():
                    # a response
                    method_name = self._pop_waitting(todo['id'])
                    self._add_queue(method_name, todo)
                else:
                    # a request that send from the server
                    self._add_queue(todo['method'], todo)

    def GetServerStatus_(self):
        return self.GetServerStatus(self.server_id)

    def GetResponse(self, _method_name, timeout_=5):
        if _method_name not in self._queue_dict:
            # new
            self._queue_dict[_method_name] = queue.Queue()
        queue_obj = None
        try:
            if timeout_ == -1:
                queue_obj = self._queue_dict[_method_name].get()
            else:
                queue_obj = self._queue_dict[_method_name].get(
                    timeout=timeout_)
        except:
            self._queue_dict[_method_name] = queue.Queue()
        if queue_obj is None:
            raise 'queue time out.'
        return queue_obj

    def _add_queue(self, _method_name, _todo):
        if _method_name is None:
            return None
        if _method_name in self._queue_dict:
            obj_ = self._queue_dict[_method_name]
        else:
            # obj_ = queue.Queue()
            # self._queue_dict[_method_name] = obj_

            # user should call GetResponse() once to create a queue
            # if don't, this msg will be abandomed.
            return None
        obj_.put(_todo)
        return obj_

    def _add_waitting(self, _id, _method_name):
        """ waiting lists
        """
        try:
            self._lock.acquire()
            self._waitting_response[_id] = _method_name
        finally:
            self._lock.release()

    def _pop_waitting(self, _id):
        """get the response of method name by id to classify
        """
        try:
            self._lock.acquire()
            if _id in self._waitting_response:
                method_ = self._waitting_response[_id]
                self._waitting_response.pop(_id)
                return method_
            else:
                return None
        finally:
            self._lock.release()

    def ChangeUsingServerID(self, id_nr):
        if id_nr > self.server_count:
            raise 'have no such a server process.'
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
            # raise an erro:
            # return 'E002: you have to send a initialize request first.'
            return None
        context = {'jsonrpc': '2.0', 'method': method, 'params': params}
        # we have to increase the ID all the time for distinguished by ECY
        self._id += 1
        if not isNotification:
            # id_text       = "ECY_"+str(self._id)
            context['id'] = self._id
            self._add_waitting(self._id, method)
        context = json.dumps(context)
        context_lenght = len(context)
        debug = "--->" + context
        self.Debug(debug)
        message = ("Content-Length: {}\r\n\r\n"
                   "{}".format(context_lenght, context))
        self.SendData(self.GetUsingServerID(),
                      message.encode(encoding="utf-8"))
        return {'ID': self._id, 'Method': method}

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
        debug = "--->" + context
        if self._debug:
            print(debug)
        message = ("Content-Length: {}\r\n\r\n"
                   "{}".format(context_lenght, context))
        self.SendData(self.server_id, message.encode(encoding="utf-8"))
        return True

    def BuildCapabilities(self):
        # {{{
        WorkspaceClientCapabilities = {
            "applyEdit": True,
            "workspaceEdit": {
                "documentChanges": True,
                "resourceOperations": ["create", "rename", "delete"],
                "failureHandling": "abort"
            },
            "didChangeConfiguration": {
                "dynamicRegistration": False
            },
            "didChangeWatchedFiles": {
                "dynamicRegistration": False
            },
            "symbol": {
                "dynamicRegistration": False,
                "symbolKind": {
                    "valueSet": [
                        1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16,
                        17, 18, 19, 20, 21, 22, 23, 24, 25, 26
                    ]
                }
            },
            "executeCommand": {
                "dynamicRegistration": False
            },
            "workspaceFolders": True,
            "configuration": False
        }

        TextDocumentClientCapabilities = {
            "synchronization": {
                "dynamicRegistration": False,
                "willSave": True,
                "willSaveWaitUntil": True,
                "didSave": True
            },
            "completion": {
                "dynamicRegistration": False,
                "completionItem": {
                    "snippetSupport": True,
                    "commitCharactersSupport": False,
                    "documentationFormat": [],
                    "deprecatedSupport": True,
                    "preselectSupport": False
                },
                "completionItemKind": {
                    "valueSet": []
                },
                "contextSupport": False
            },
            "hover": {
                "dynamicRegistration": False,
                "contentFormat": []
            },
            "signatrueHelp": {
                "dynamicRegistration": False,
                "signatrueInformation": {
                    "documentationFormat": [],
                    "parameterInformation": {
                        "labelOffsetSupport": True
                    }
                }
            },
            "references": {
                "dynamicRegistration": False
            },
            "documentHighlight": {
                "dynamicRegistration": False
            },
            "documentSymbol": {
                "dynamicRegistration": False,
                "symbolKind": {
                    "valueSet": []
                },
                "hierarchicalDocumentSymbolSupport": True
            },
            "formatting": {
                "dynamicRegistration": False
            },
            "rangeFormatting": {
                "dynamicRegistration": False
            },
            "onTypeFormatting": {
                "dynamicRegistration": False
            },
            "declaration": {
                "dynamicRegistration": False,
                "linkSupport": True
            },
            "definition": {
                "dynamicRegistration": False,
                "linkSupport": True
            },
            "typeDefinition": {
                "dynamicRegistration": False,
                "linkSupport": True
            },
            "implementation": {
                "dynamicRegistration": False,
                "linkSupport": True
            },
            "codeAction": {
                "dynamicRegistration": False,
                "codeActionLiteralSupport": {
                    "codeActionKind": {
                        "valueSet": []
                    }
                }
            },
            "codeLens": {
                "dynamicRegistration": False
            },
            "documentLink": {
                "dynamicRegistration": False
            },
            "colorProvider": {
                "dynamicRegistration": False
            },
            "rename": {
                "dynamicRegistration": False,
                "prepareSupport": True
            },
            "publishDiagnostics": {
                "relatedInformation": True
            },
            "foldingRange": {
                "dynamicRegistration": False,
                "rangeLimit": 100,
                "lineFoldingOnly": True
            }
        }

        Capabilities = {
            'workspace': WorkspaceClientCapabilities,
            'textDocument': TextDocumentClientCapabilities,
            'experimental': None
        }
        return Capabilities
# }}}

    def initialize(self,
                   processId=None,
                   rootUri=None,
                   initializationOptions=None,
                   trace='off',
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
        params = {
            'processId': processId,
            'rootUri': rootUri,
            'initializationOptions': initializationOptions,
            'workspaceFolders': workspaceFolders,
            'capabilities': capabilities,
            'trace': trace
        }
        return self._build_send(params, 'initialize')

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

    def configuration(self, ids, results=[]):
        """ workspace/configuration, a response send to Server.
        """
        return self._build_response(results, ids)

    def wordDoneProgress(self, ids):
        return self._build_response(None, ids)

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

    def didchange(self, uri, text, version=None, range_=None, rangLength=None):
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
            'contentChanges': [TextDocumentContentChangeEvent]
        }
        return self._build_send(params,
                                'textDocument/didChange',
                                isNotification=True)

    def completionItem_resolve(self, completion_item):
        params = {'CompletionItem': completion_item}
        return self._build_send(params, 'completionItem/resolve')

    def _get_progress_token(self):
        if self.workDoneToken_id is None:
            self.workDoneToken_id = 0
        self.workDoneToken_id += 1
        return self.workDoneToken_id

    def _get_workdone_token(self):
        if workDoneToken is None:
            self.workDoneToken_id = 0
        self.workDoneToken_id += 1
        return self.workDoneToken_id

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

    def codeAction(self,
                   uri,
                   start_position,
                   end_position,
                   diagnostic=[],
                   workDoneToken=None,
                   ProgressToken=None):

        if workDoneToken is None:
            self.workDoneToken_id += 1
            workDoneToken = self.workDoneToken_id
        if ProgressToken is None:
            self.workDoneToken_id += 1
            ProgressToken = self.workDoneToken_id

        ranges = {'start': start_position, 'end': end_position}

        params = {
            'workDoneToken': workDoneToken,
            'partialResultToken': ProgressToken,
            'range': ranges,
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

    def hover(self, uri, position):
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

    def declaration(self, position, uri):
        params = {'textDocument': {'uri': uri}, 'position': position}
        return self._build_send(params, 'textDocument/definition')

    def PathToUri(self, file_path):
        return urljoin('file:', pathname2url(file_path))

    def UriToPath(self, uri):
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
