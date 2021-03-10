from ECY_engines import lsp
from ECY_engines.snippet.ultisnips import ultisnips


class Operate(lsp.Operate):
    def __init__(self):
        lsp.Operate.__init__(self,
                             'ECY_engines.html.lsp.html_lsp',
                             'html-languageserver --stdio',
                             languageId='html')
        self.snip = ultisnips.Operate()

    def OnBufferEnter(self, context):
        super().OnCompletion(context)
        self.snip.OnBufferEnter(context)

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

            results_format['abbr'] = item_name
            results_format['word'] = item_name

            show_list.append(results_format)

        if len(show_list) == 0:
            return self.snip.OnCompletion(context)
        context['show_list'] = show_list
        return context
