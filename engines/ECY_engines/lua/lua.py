from ECY_engines import lsp
from ECY import rpc
from ECY_engines.snippet.ultisnips import ultisnips
from ECY import utils


class Operate(lsp.Operate):
    def __init__(self, engine_name):
        lsp.Operate.__init__(self, engine_name, languageId='lua')

    def OnCompletion(self, context):
        context = super().OnCompletion(context)
        context = super()._to_ECY_format(context)
        return context
