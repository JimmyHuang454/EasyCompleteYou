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
        if res is not None:
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
        context = super().OnCompletion(context)
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

            results_format['kind'] = self._lsp.GetKindNameByNumber(
                item['kind'])

            if 'filterText' in item:
                item_name = item['filterText']
            else:
                item_name = item['label']

            if results_format['kind'] == 'File':
                name_len = len(item_name)
                if item_name[name_len - 1] in ['>', '"'] and name_len >= 2:
                    item_name = item_name[:name_len - 1]

            results_format['abbr'] = item_name
            results_format['word'] = item_name

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

            insertTextFormat = 0
            if 'insertTextFormat' in item:
                insertTextFormat = item['insertTextFormat']
                if insertTextFormat == 2:
                    temp = item['insertText']
                    if '$' in temp or '(' in temp or '{' in temp:
                        temp = temp.replace('{\\}', '\{\}')
                        results_format['snippet'] = temp
                        results_format['kind'] += '~'

            if 'completion_text_edit' in item and False:
                results_format['completion_text_edit'] = item[
                    'completion_text_edit']
                results_format['word'] = item['textEdit']['newText']

            if 'documentation' in item:
                if type(item['documentation']) is str:
                    temp = item['documentation'].split('\n')
                elif type(item['documentation']) is dict:
                    temp = item['documentation']['value'].split('\n')

                document.extend(temp)

            results_format['info'] = '\n'.join(document)
            show_list.append(results_format)
        context['show_list'] = show_list
        return context
