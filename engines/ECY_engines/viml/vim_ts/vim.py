from ECY_engines import lsp
from ECY import rpc


class Operate(lsp.Operate):
    def __init__(self):

        initializationOptions = {
            "isNeovim": not rpc.GetVaribal('g:is_vim'),
            "iskeyword": "@,48-57,_,192-255,-#",
            "vimruntime": rpc.GetVaribal('$VIMRUNTIME'),
            "runtimepath": rpc.GetVaribal('&rtp'),
            "diagnostic": {
                "enable": True
            },
            "indexes": {
                "runtimepath":
                True,
                "gap":
                100,
                "count":
                3,
                "projectRootPatterns":
                ["strange-root-pattern", ".git", "autoload", "plugin"]
            },
            "suggest": {
                "fromVimruntime": True,
                "fromRuntimepath": False
            }
        }

        lsp.Operate.__init__(self,
                             'ECY_engines.viml.vim_ts.vim',
                             'vim-language-server --stdio',
                             languageId='viml',
                             refresh_regex=r'[\w+\:\#\&]',
                             initializationOptions=initializationOptions)

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
        context['show_list'] = show_list
        return context
