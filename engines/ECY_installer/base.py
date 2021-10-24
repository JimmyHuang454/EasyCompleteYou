from ECY_installer import pypi_tools


class Install(object):
    """
    """
    def __init__(self):
        self.name: str = ''

    def Windows(self, context: dict) -> dict:
        pass

    def Linux(self, context: dict) -> dict:
        pass

    def Mac(self, context: dict) -> dict:
        pass

    def Readme(self, context: dict) -> str:
        return ""
