from ECY_engines import lsp
from ECY import utils


class Operate(lsp.Operate):
    def __init__(self):
        self.engine_name = 'ECY_engines.all.efm'
        starting_cmd = utils.GetEngineConfig(self.engine_name, 'cmd')
        initializationOptions = utils.GetEngineConfig(self.engine_name,
                                                      'initializationOptions')
        lsp.Operate.__init__(self,
                             self.engine_name,
                             starting_cmd,
                             initializationOptions=initializationOptions,
                             languageId='all')
