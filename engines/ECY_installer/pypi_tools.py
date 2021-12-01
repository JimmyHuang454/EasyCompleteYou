import tarfile
import requests
import json

from ECY_installer import base


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


def GetLastestVersion(pack_name: str, dist: str) -> list:
    pypi_json = 'https://%s/pypi/%s/json' % (dist, pack_name)
    res = requests.get(pypi_json).text
    if res.find('Not Found') != -1:
        print(pypi_json)
        print(res)
        raise ValueError("package '%s' not found." % pack_name)
    res = json.loads(res)
    version = res['info']['version']
    release = res['releases'][version]
    for item in release:
        if item['filename'].endswith('gz'):
            print(item)
            return item
    raise ValueError("Can not find last_version.")


def GetUrl(info: dict, dist: str) -> str:
    url: str = info['url']
    item = url.split('packages')
    return "https://%s/packages%s" % (dist, item[1])


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


def Install(pack_name: str, save_dir: str) -> str:
    # pack_name = pack_name.replace('_', '-')
    dist: str = GetDIST()
    last_version = GetLastestVersion(pack_name, dist)
    last_version_url = GetUrl(last_version, dist)
    local_path = '%s/%s' % (save_dir, last_version['filename'])
    base.DownloadFileWithProcessBar(last_version_url, local_path)
    Unpack(local_path, save_dir)
    return local_path
