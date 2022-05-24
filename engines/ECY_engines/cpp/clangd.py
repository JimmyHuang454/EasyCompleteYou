import copy

from ECY_engines import lsp
from ECY.debug import logger
from ECY import utils


class Operate(lsp.Operate):
    def __init__(self, engine_name):
        starting_cmd_argv = ''
        if utils.GetEngineConfig(engine_name, 'all_scopes_completion'):
            starting_cmd_argv += '--all-scopes-completion '

        if utils.GetEngineConfig(engine_name, 'background_index'):
            starting_cmd_argv += '--background-index '

        clang_format_fallback_style = utils.GetEngineConfig(
            engine_name, 'clang_format_fallback_style')
        if clang_format_fallback_style != "":
            starting_cmd_argv += '--fallback-style="%s" ' % clang_format_fallback_style

        pch_storage = utils.GetEngineConfig(engine_name, 'pch_storage')
        if pch_storage != "" and pch_storage in ['disk', 'memory']:
            starting_cmd_argv += '--pch-storage="%s" ' % pch_storage

        query_dirver = utils.GetEngineConfig(engine_name, 'query_dirver')
        if query_dirver != "":
            starting_cmd_argv += '--query-driver="%s" ' % query_dirver

        if utils.GetEngineConfig(engine_name, 'use_completion_cache'):
            starting_cmd_argv += '--limit-results=0 '
            lsp.Operate.__init__(self,
                                 engine_name,
                                 starting_cmd_argv=starting_cmd_argv,
                                 languageId='cpp',
                                 use_completion_cache=True,
                                 use_completion_cache_position=True)
        else:
            lsp.Operate.__init__(self,
                                 engine_name,
                                 starting_cmd_argv=starting_cmd_argv,
                                 languageId='cpp')

    def SwitchSourceHeader(self, context):
        params = context['params']
        uri = params['buffer_path']
        uri = self._lsp.PathToUri(uri)

        params = {'uri': uri}
        res = self._lsp._build_send(
            params, 'textDocument/switchSourceHeader').GetResponse()

        if 'error' in res:
            self._goto_response(res)  # show error msg
            return

        res = res['result']

        if res is None:
            self._show_msg('res is None')
            return

        self._goto_response({
            'result': [{
                "uri": res,
                "range": {
                    "start": {
                        "line": 0,
                        "character": 1
                    },
                    "end": {
                        "line": 0,
                        "character": 6
                    }
                }
            }]
        })

    def OnCompletion(self, context):
        lsp_context = super()._to_LSP_format(context)
        if lsp_context is None:
            return  # server not supports.

        ECY_context = super()._to_ECY_format(copy.deepcopy(lsp_context))
        i = 0
        for item in ECY_context['show_list']:
            original_data = lsp_context['show_list'][i]

            if 'filterText' in original_data:
                item_name = original_data['filterText']
            else:
                item_name = original_data['label']

            item['abbr'] = item_name
            item['word'] = item_name
            item['kind'] = self._lsp.GetKindNameByNumber(original_data['kind'])
            if 'snippet' in item:
                del item['snippet']

            insertTextFormat = 0
            if 'insertTextFormat' in original_data:
                insertTextFormat = original_data['insertTextFormat']
                if insertTextFormat == 2:
                    temp = original_data['insertText']
                    if '$' in temp or '(' in temp or '{' in temp:
                        temp = temp.replace('{\\}', '\{\}')
                        item['snippet'] = temp
                        item['kind'] += '~'

            i += 1

        return ECY_context
