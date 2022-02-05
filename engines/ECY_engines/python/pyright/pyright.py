from ECY_engines import lsp
from ECY import utils


class Operate(lsp.Operate):
    def __init__(self, engine_name):
        lsp.Operate.__init__(self,
                             engine_name,
                             languageId='python',
                             starting_cmd_argv='--stdio')

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

            item_name = item['label']

            if 'insertText' in item:
                item_name = item['insertText']
            else:
                pass
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
