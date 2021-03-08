from ECY_engines import lsp


class Operate(lsp.Operate):
    """
    """
    def __init__(self):
        lsp.Operate.__init__(self,
                             'ECY_engines.rust.rust_analyzer.rust_analyzer',
                             'rust_analyzer',
                             languageId='rust')

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
            show_list.append(results_format)
        context['show_list'] = show_list
        return context
