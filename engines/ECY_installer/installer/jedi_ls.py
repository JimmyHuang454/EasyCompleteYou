from ECY_installer import pypi_tools
from ECY_installer import base


class Install(base.Install):
    """
    """
    def __init__(self):
        self.name = ''

    def CleanWindows(self, context):
        pass

    def Windows(self, context):
        save_dir = context['save_dir']
        return self.InstallEXE('jedi', 'Windows', save_dir)

    def Linux(self, context):
        save_dir = context['save_dir']
        return self.InstallEXE('jedi', 'Linux', save_dir)

    def macOS(self, context):
        save_dir = context['save_dir']
        return self.InstallEXE('jedi', 'macOS', save_dir)
