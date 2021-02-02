class Operate(object):
    """
    """
    def __init__(self):
        self.engine_name = 'label'

    def OnBufferEnter(self, context):
        context['hah'] = 1
        return context
