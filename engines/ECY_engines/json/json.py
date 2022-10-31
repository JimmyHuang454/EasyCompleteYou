from ECY_engines import lsp
from ECY import rpc
from ECY_engines.snippet import ultisnips
from ECY import utils


class Operate(lsp.Operate):
    def __init__(self, engine_name):
        lsp.Operate.__init__(self, engine_name)
        self.snip = ultisnips.Operate()

    def OnBufferEnter(self, context):
        super().OnBufferEnter(context)
        self.snip.OnBufferEnter(context)
