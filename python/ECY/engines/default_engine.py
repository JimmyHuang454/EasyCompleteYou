from loguru import logger

class Operate(object):
    """
    """
    def __init__(self):
        self.engine_name = 'label'

    def OnBufferEnter(self, context):
        return context
