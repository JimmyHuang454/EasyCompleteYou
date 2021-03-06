from ECY_engines import lsp
from ECY import utils


class Operate(lsp.Operate):
    """
    """
    def __init__(self):
        engine_name = 'ECY_engines.golang.gopls.gopls'
        starting_cmd = utils.GetEngineConfig(engine_name, 'cmd')
        lsp.Operate.__init__(self,
                             engine_name,
                             starting_cmd,
                             languageId='golang')

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

            item_name = item['label']
            results_format['kind'] = self._lsp.GetKindNameByNumber(
                item['kind'])
            results_format['abbr'] = item_name
            results_format['word'] = item_name

            if 'detail' in item:
                results_format['menu'] = item['detail']
            if 'documentation' in item:
                results_format['info'] = self._format_markupContent(
                    item['documentation'])
            if 'insertTextFormat' in item:
                if item['insertTextFormat'] == 2 and 'textEdit' in item:
                    textEdit = item['textEdit']
                    results_format['snippet'] = textEdit['newText']
                    results_format['kind'] += '~'

            show_list.append(results_format)
        context['show_list'] = show_list
        return context
