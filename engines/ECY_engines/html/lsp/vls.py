from ECY_engines import lsp
from ECY import rpc
from ECY_engines.snippet.ultisnips import ultisnips
from ECY import utils


class Operate(lsp.Operate):
    def __init__(self):
        self.engine_name = 'ECY_engines.html.lsp.vls'
        starting_cmd = utils.GetEngineConfig(self.engine_name, 'cmd')
        lsp.Operate.__init__(self,
                             self.engine_name,
                             starting_cmd,
                             refresh_regex=r'[\w+\-]',
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
