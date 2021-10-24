from ECY_installer import pypi_tools
from ECY_installer import base


class Install(base.Install):
    """
    """
    def __init__(self):
        self.name = ''

    def Windows(self, context):
        save_dir = context['save_dir']
        installed_dir = ''
        installed_dir = pypi_tools.Pypi('ECY_Clangd_windows', save_dir)
        print("installed clangd")
        return {'cmd': installed_dir}

    def Linux(self, context):
        save_dir = context['save_dir']
        installed_dir = pypi_tools.Pypi('ECY_Clangd_linux', save_dir)
        return {'cmd': installed_dir}

    def Mac(self, context):
        save_dir = context['save_dir']
        installed_dir = pypi_tools.Pypi('ECY_Clangd_windows', save_dir)
        return {'cmd': installed_dir}
