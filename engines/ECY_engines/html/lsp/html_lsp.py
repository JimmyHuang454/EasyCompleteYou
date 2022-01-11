from ECY_engines import lsp
from ECY_engines.snippet.ultisnips import ultisnips


class Operate(lsp.Operate):
    def __init__(self, engine_name):
        lsp.Operate.__init__(self,
                             engine_name,
                             starting_cmd_argv='--stdio',
                             refresh_regex=r'[\-\w+]',
                             languageId='html')
        self.snip = ultisnips.Operate()

    def OnBufferEnter(self, context):
        super().OnCompletion(context)
        self.snip.OnBufferEnter(context)

    def OnCompletion(self, context):
        context = super().OnCompletion(context)
        context = super()._to_ECY_format(context)
        return context
