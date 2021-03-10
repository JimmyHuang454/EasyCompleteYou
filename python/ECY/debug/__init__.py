try:
    from loguru import logger as ll
    logger = ll
    has_loguru = True
except:
    import logging
    import sys
    has_loguru = False
    logger = logging.getLogger('ECY_debug')
    logger.removeHandler(sys.stderr)
    # add no hanlder

__all__ = ["logger", 'has_loguru']
