# -*- coding: UTF-8 -*-
from loguru import logger
from ECY import rpc
import ECY.engines.engines as engines

logger.remove()  # disable stdout output
logger.add("ECY_Debug_log/{time}.log", level="DEBUG")

rpc.BlindEvent(engines.Mannager())
rpc.Daemon()
