# -*- coding: UTF-8 -*-
from loguru import logger
from ECY import rpc
import ECY.engines as engines

logger.remove()
logger.add("ECY_Debug_log/{time}.log", level="DEBUG")

rpc.BlindEvent(engines.Mannager())
rpc.Daemon()
