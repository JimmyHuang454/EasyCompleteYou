import urllib.request
from tqdm import tqdm


class DownloadProgressBar(tqdm):
    def update_to(self, b=1, bsize=1, tsize=None):
        if tsize is not None:
            self.total = tsize
        self.update(b * bsize - self.n)


def DownloadFile(url, output_path):
    with DownloadProgressBar(unit='B',
                             unit_scale=True,
                             miniters=1,
                             desc=url.split('/')[-1]) as t:
        urllib.request.urlretrieve(url,
                                   filename=output_path,
                                   reporthook=t.update_to)


ECY_exe_url = 'https://github.com/JimmyHuang454/ECY_exe/releases/latest/download/%s' % (
    'ECY_Windows.exe')

print(ECY_exe_url)

DownloadFile(
    ECY_exe_url,
    'C:/Users/qwer/Desktop/vimrc/myproject/ECY/RPC/EasyCompleteYou2/engines/ECY_installer/ECY_Windows.exe'
)
