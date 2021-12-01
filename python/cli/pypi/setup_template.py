import time
from os import path
from platform import system
from setuptools import Extension, setup


def GetCurrentOS():
    temp = sys.platform
    if temp == 'win32':
        return 'Windows'
    if temp == 'darwin':
        return 'macOS'
    return 'Linux'


NAME = "ECY_{platform}_{exe}"

LONG_DESCRIPTION = "Clone from https://github.com/JimmyHuang454/ECY_exe"

setup(name=NAME,
      version="{version}",
      include_package_data=True,
      zip_safe=False,
      maintainer="jimmy huang",
      maintainer_email="1902161621@qq.com",
      author="jimmy huang",
      author_email="1902161621@qq.com",
      url="https://github.com/JimmyHuang454/ECY_exe",
      license="MIT",
      platforms=["any"],
      python_requires=">=3.3",
      description="",
      long_description=LONG_DESCRIPTION,
      long_description_content_type="text/markdown",
      classifiers=[
          "License :: OSI Approved :: MIT License",
          "Topic :: Software Development :: Compilers",
          "Topic :: Text Processing :: Linguistic",
      ],
      packages=['ECY_exe'])
