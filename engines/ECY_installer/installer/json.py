from ECY_installer import base


class Install(base.Install):
    def __init__(self):
        base.Install.__init__(self, 'json')
