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
import shutil
import base64
import shutil

from urllib.parse import urljoin
from urllib.request import pathname2url
from urllib.parse import urlparse
from urllib.request import url2pathname
from xmlrpc.server import SimpleXMLRPCServer
import xmlrpc.client
from pygments import highlight
from pygments.lexers import PythonLexer
from pygments.formatters.terminal256 import Terminal256Formatter

# determine if application is a script file or frozen exe
if getattr(sys, 'frozen', False):
    BASE_DIR = os.path.dirname(sys.executable)
elif __file__:
    BASE_DIR = os.path.dirname(__file__)

sys.path.append(BASE_DIR)

import client_main

client_main.main()
