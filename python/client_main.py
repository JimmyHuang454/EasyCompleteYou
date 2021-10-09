# -*- coding: UTF-8 -*-
from ECY import rpc
import ECY.engines.engines as engines
from ECY.debug import logger
from ECY.debug import has_loguru
import argparse
import os
import sys

BASE_DIR = os.path.abspath(os.path.dirname(__file__))

#######################################################################
#                                flags                                #
#######################################################################
parser = argparse.ArgumentParser(
    description='EasyCompleteYou, Easily complete you.')
parser.add_argument('--debug_log', action='store_true', help='debug with log.')
parser.add_argument('--ci', action='store_true', help='for CI')
parser.add_argument('--log_dir', help='the file of log to output.')
parser.add_argument('--sources_dir', help='Where the sources_dir is.')
g_args = parser.parse_args()

if g_args.ci:
    print('quited with --ci')
    quit()

if g_args.sources_dir is not None:
    sys.path.append(g_args.sources_dir)

#######################################################################
#                                Debug                                #
#######################################################################
if has_loguru:
    logger.remove()
    if g_args.log_dir is None:
        path = BASE_DIR + '/ECY_debug.log'
    else:
        path = g_args.log_dir

    if g_args.debug_log:
        with open(path, 'w', encoding='utf-8') as f:
            f.write('')
        level = "DEBUG"
        logger.add(path, level=level, encoding='utf-8')


def main():
    rpc.BlindEvent(engines.Mannager())
    rpc.Daemon()


if __name__ == '__main__':
    main()
