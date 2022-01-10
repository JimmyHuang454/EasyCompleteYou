# -*- coding: UTF-8 -*-
import logging
import argparse
import os
import sys
import subprocess

from ECY import rpc
from ECY import utils
import ECY.engines.engines as engines
from ECY.debug import logger

# determine if application is a script file or frozen exe
if getattr(sys, 'frozen', False):
    BASE_DIR = os.path.dirname(sys.executable)
elif __file__:
    BASE_DIR = os.path.dirname(__file__)

#######################################################################
#                                flags                                #
#######################################################################
parser = argparse.ArgumentParser(
    description='EasyCompleteYou, Easily complete you.')
parser.add_argument('--debug_log', action='store_true', help='debug with log.')
parser.add_argument('--ci', action='store_true', help='for CI')
parser.add_argument('--log_path', help='the file of log to output.')
parser.add_argument('--sources_dir', help='Where the sources_dir is.')
parser.add_argument('--install', help='install + engine_name')
parser.add_argument('--uninstall', help='uninstall + engine_name')
g_args = parser.parse_args()

if g_args.ci:
    print('quited with --ci')
    sys.exit()

IS_INSTALL = False
if g_args.install is not None or g_args.uninstall is not None:
    IS_INSTALL = True

if g_args.sources_dir is not None:
    sys.path.append(g_args.sources_dir)

#######################################################################
#                                Debug                                #
#######################################################################

if g_args.debug_log and not IS_INSTALL:
    if g_args.log_path is None:
        output_log_dir = BASE_DIR + '/ECY_debug.log'
    else:
        output_log_dir = g_args.log_path

    fileHandler = logging.FileHandler(output_log_dir,
                                      mode="w",
                                      encoding="utf-8")
    formatter = logging.Formatter(
        '%(asctime)s %(filename)s:%(lineno)d | %(message)s')
    fileHandler.setFormatter(formatter)
    logger.addHandler(fileHandler)
    logger.setLevel(logging.DEBUG)
    logger.debug(BASE_DIR)


def main():
    if utils.GetCurrentOS() != "Windows":
        subprocess.Popen('sudo chmod -R 775 %s' % BASE_DIR, shell=True).wait()

    if IS_INSTALL:
        from ECY_installer import install_cli
        if g_args.install is not None:
            install_cli.Install(g_args.install)
        else:
            install_cli.UnInstall(g_args.install)
    else:
        rpc.BlindEvent(engines.Mannager())
        rpc.Daemon()


if __name__ == '__main__':
    main()
