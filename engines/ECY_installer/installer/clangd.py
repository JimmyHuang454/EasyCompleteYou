import os

from ECY_installer import pypi_tools
from ECY_installer import base


class Install(base.Install):
    """
    """
    def __init__(self):
        base.Install.__init__(self, 'clangd')

    def GetClangdBinDir(self, installed_dir: str) -> str:
        for _, dirs, files in os.walk(installed_dir):
            for item in dirs:
                if item.find('clangd') != -1:
                    return installed_dir + '/' + item + '/bin'
            return

    def Windows(self, context):
        res = self.InstallEXE(self.name, 'Windows', context['save_dir'])
        res['cmd'] = self.GetClangdBinDir(res['installed_dir'] +
                                          '/ECY_exe') + '/clangd.exe'
        return res

    def Linux(self, context):
        res = self.InstallEXE(self.name, 'Linux', context['save_dir'])
        res['cmd'] = self.GetClangdBinDir(res['installed_dir'] +
                                          '/ECY_exe') + '/clangd'
        return res

    def macOS(self, context):
        res = self.InstallEXE(self.name, 'macOS', context['save_dir'])
        res['cmd'] = self.GetClangdBinDir(res['installed_dir'] +
                                          '/ECY_exe') + '/clangd'
        return res
