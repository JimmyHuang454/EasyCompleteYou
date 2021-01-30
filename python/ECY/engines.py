from loguru import logger
from ECY import rpc


class Mannager(object):
    """docstring for Mannager"""
    def __init__(self):
        pass

    def BufEnter(self):
        path = rpc.DoCall('ECY#utility#GetCurrentBufferPath')
        logger.debug('On BufEnter %s' % (path))
