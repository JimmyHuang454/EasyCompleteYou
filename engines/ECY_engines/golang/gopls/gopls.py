from ECY_engines import lsp


class Operate(object):
    """
    """
    def __init__(self):
        self.lsp = lsp.Operate('ECY_engines.golang.gopls.gopls', 'gopls')

    def OnCompletion(self, context):
        context = self.lsp.OnCompletion(context)
        if context is None:
            return   # server not supports.
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
            results_format['kind'] = self.lsp._lsp.GetKindNameByNumber(
                item['kind'])
            results_format['abbr'] = item_name
            results_format['word'] = item_name
            show_list.append(results_format)
        context['show_list'] = show_list
        return context
