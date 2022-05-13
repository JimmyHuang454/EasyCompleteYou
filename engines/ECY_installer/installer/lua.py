import os

from ECY_installer import pypi_tools
from ECY_installer import base


class Install(base.Install):
    """
    """
    def __init__(self):
        base.Install.__init__(self, 'lua')

    def Windows(self, context):
        res = self.InstallEXE(self.name, 'Windows', context['save_dir'])
        res['cmd'] = res[
            'installed_dir'] + '/ECY_exe/bin/lua-language-server.exe'
        return res

    def Linux(self, context):
        res = self.InstallEXE(self.name, 'Linux', context['save_dir'])
        res['cmd'] = res['installed_dir'] + '/ECY_exe/bin/lua-language-server'
        return res

    def macOS(self, context):
        res = self.InstallEXE(self.name, 'macOS', context['save_dir'])
        res['cmd'] = res['installed_dir'] + '/ECY_exe/bin/lua-language-server'
        return res
