from ECY_engines import lsp


class Operate(lsp.Operate):
    def __init__(self, engine_name):
        lsp.Operate.__init__(self, engine_name, languageId='rust')
