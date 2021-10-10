# -*- coding: UTF-8 -*-
import logging
import argparse
import os
import sys

from ECY import rpc
import ECY.engines.engines as engines
from ECY.debug import logger

BASE_DIR = os.path.abspath(os.path.dirname(__file__))

#######################################################################
#                                flags                                #
#######################################################################
parser = argparse.ArgumentParser(
    description='EasyCompleteYou, Easily complete you.')
parser.add_argument('--debug_log', action='store_true', help='debug with log.')
parser.add_argument('--ci', action='store_true', help='for CI')
parser.add_argument('--log_path', help='the file of log to output.')
parser.add_argument('--sources_dir', help='Where the sources_dir is.')
g_args = parser.parse_args()

if g_args.ci:
    print('quited with --ci')
    sys.exit()

if g_args.sources_dir is not None:
    sys.path.append(g_args.sources_dir)

#######################################################################
#                                Debug                                #
#######################################################################

if g_args.debug_log:
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
    rpc.BlindEvent(engines.Mannager())
    rpc.Daemon()


if __name__ == '__main__':
    main()
