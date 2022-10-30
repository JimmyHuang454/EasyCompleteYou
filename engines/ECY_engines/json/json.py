from ECY_engines import lsp
from ECY import rpc
from ECY_engines.snippet.ultisnips import ultisnips
from ECY import utils


class Operate(lsp.Operate):
    def __init__(self, engine_name):
        lsp.Operate.__init__(self,
                             engine_name,
                             starting_cmd_argv='--stdio',
                             refresh_regex=r'[\-\@\w+]')
        self.snip = ultisnips.Operate()

    def OnBufferEnter(self, context):
        super().OnBufferEnter(context)
        self.snip.OnBufferEnter(context)
