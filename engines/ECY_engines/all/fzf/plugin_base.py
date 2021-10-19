class Plugin(object):
    def __init__(self, event_id):
        self.engine_name = ''
        self.event_id = event_id

    def RegKeyBind(self):
        return {}

    def GetSource(self, event):
        return []

    def Closed(self, event):
        pass

    def Preview(self, event):
        return ''
