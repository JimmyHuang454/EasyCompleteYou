from ECY_engines import lsp
from ECY import rpc


class Operate(lsp.Operate):
    def __init__(self, engine_name):

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
                             engine_name,
                             languageId='viml',
                             starting_cmd_argv='--stdio',
                             refresh_regex=r'[\w+\#\&]',
                             initializationOptions=initializationOptions)

    def OnCompletion(self, context):
        context = super().OnCompletion(context)
        context = super()._to_ECY_format(context)
        return context
