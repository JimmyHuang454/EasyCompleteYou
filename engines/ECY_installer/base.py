from ECY_installer import pypi_tools


class Install(object):
    """
    """
    def __init__(self):
        self.name: str = ''

    def CleanWindows(self, contextd: dict) -> dict:
        return {}

    def Windows(self, context: dict) -> dict:
        return {}

    def Linux(self, context: dict) -> dict:
        return {}

    def Mac(self, context: dict) -> dict:
        return {}

    def Readme(self, context: dict) -> str:
        return ""
