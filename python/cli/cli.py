# We import these module here, so as to be detected by pyinstaller.
import logging
import argparse
import os
import sys
import re
import queue
import importlib
import copy
import threading
import json
import subprocess
import shlex
import base64
import shutil
import tarfile

from urllib.parse import urljoin, urlparse
from urllib.request import pathname2url, urlretrieve, url2pathname
from xmlrpc.server import SimpleXMLRPCServer
import xmlrpc.client

import pygments
import requests
from tqdm import tqdm
from colorama import init
from termcolor import colored

# determine if application is a script file or frozen exe
if getattr(sys, 'frozen', False):
    BASE_DIR = os.path.dirname(sys.executable)
elif __file__:
    BASE_DIR = os.path.dirname(__file__)

sys.path.append(BASE_DIR)

import client_main

client_main.main()
