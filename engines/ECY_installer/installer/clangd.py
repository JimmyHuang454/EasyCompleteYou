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
        installed_dir = ''
        installed_dir = pypi_tools.Install('ECY_windows_clangd', save_dir)
        return {'cmd': installed_dir + '/clangd_files/bin/clangd.exe'}

    def Linux(self, context):
        save_dir = context['save_dir']
        installed_dir = pypi_tools.Install('ECY_linux_clangd', save_dir)
        return {'cmd': installed_dir + '/clangd_files/bin/clangd.exe'}

    def Mac(self, context):
        save_dir = context['save_dir']
        installed_dir = pypi_tools.Install('ECY_mac_clangd', save_dir)
        return {'cmd': installed_dir}
