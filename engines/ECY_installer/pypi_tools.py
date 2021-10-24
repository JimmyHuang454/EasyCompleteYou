import tarfile
import requests
import json


def GetDIST() -> str:
    res: str = requests.get('http://ip-api.com/json/?lang=zh-CN').text
    dist: dict = {'CN': 'pypi.tuna.tsinghua.edu.cn'}
    res = json.loads(res)
    countryCode: str = res['countryCode']
    print(res)

    if countryCode not in dist:
        res = 'pypi.org'
    else:
        res = dist[countryCode]
    print(res)
    return res


DISTRIBUTION: str = ''


def GetLastestVersion(pack_name: str) -> list:
    pypi_json = 'https://%s/pypi/%s/json' % (DISTRIBUTION, pack_name)
    res = requests.get(pypi_json).text
    res = json.loads(res)
    version = res['info']['version']
    release = res['releases'][version]
    for item in release:
        if item['filename'].endswith('gz'):
            print(item)
            return item
    raise ValueError("Can not find last_version.")


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


def GetUrl(info: dict) -> str:
    url: str = info['url']
    item = url.split('packages')
    return "https://%s/packages%s" % (DISTRIBUTION, item[1])


def Unpack(zip_path: str, output_dir: str) -> None:
    print(output_dir)
    if zip_path.endswith("tar.gz"):
        tar = tarfile.open(zip_path, "r:gz")
        tar.extractall(output_dir)
        tar.close()
    elif zip_path.endswith("tar"):
        tar = tarfile.open(zip_path, "r:")
        tar.extractall(output_dir)
        tar.close()


def Pypi(pack_name: str, save_dir: str) -> str:
    DISTRIBUTION: str = GetDIST()
    last_version = GetLastestVersion(PACK_NAME)
    last_version_url = GetUrl(last_version)
    local_path = '%s/%s' % (save_dir, last_version['filename'])
    DownloadFile(last_version_url, local_path)
    Unpack(local_path, save_dir)
    return local_path
