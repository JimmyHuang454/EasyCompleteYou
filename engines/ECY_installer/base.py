from urllib.request import urlretrieve

from tqdm import tqdm
from colorama import init

init()
from termcolor import colored

from ECY_installer import pypi_tools


class DownloadProgressBar(tqdm):
    def update_to(self, b=1, bsize=1, tsize=None):
        if tsize is not None:
            self.total = tsize
        self.update(b * bsize - self.n)


def DownloadFileWithProcessBar(url: str, output_path: str):
    with DownloadProgressBar(unit='B',
                             unit_scale=True,
                             miniters=1,
                             desc=url.split('/')[-1]) as t:
        urlretrieve(url, filename=output_path, reporthook=t.update_to)


def PrintGreen(msg, colored_msg):
    print(msg, colored(colored_msg, 'white', 'on_green'))


def PrintPink(msg, colored_msg):
    print(msg, colored(colored_msg, 'white', 'on_magenta'))


def DownloadFile(url: str, output_path: str) -> None:
    print(url)
    with requests.get(url, stream=True) as r:
        r.raise_for_status()
        with open(output_path, 'wb') as f:
            for chunk in r.iter_content(chunk_size=8192):
                # If you have chunk encoded response uncomment if
                # and set chunk_size parameter to None.
                #if chunk:
                f.write(chunk)
            f.close()


class Install(object):
    """
    """
    def __init__(self):
        self.name: str = ''

    def DownloadFile(self, url, output_path):
        DownloadFile(url, output_path)

    def DownloadFileWithProcessBar(self, url, output_path):
        DownloadFileWithProcessBar(url, output_path)

    def CleanWindows(self, contextd: dict) -> dict:
        return {}

    def CleanLinux(self, contextd: dict) -> dict:
        return {}

    def CleanmacOS(self, contextd: dict) -> dict:
        return {}

    def Windows(self, context: dict) -> dict:
        return {}

    def Linux(self, context: dict) -> dict:
        return {}

    def macOS(self, context: dict) -> dict:
        return {}

    def CheckmacOS(self, context: dict) -> dict:
        return {}

    def CheckmacOS(self, context: dict) -> dict:
        return {}

    def Readme(self, context: dict) -> str:
        return ""
