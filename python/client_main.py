# -*- coding: UTF-8 -*-
from loguru import logger
logger.remove()  # disable stdout output
logger.add(
    "C:/Users/qwer/Desktop/vimrc/myproject/ECY/RPC/EasyCompleteYou/ECY_Debug_log/{time}.log",
    level="DEBUG")

from ECY import rpc
import ECY.engines.engines as engines


rpc.BlindEvent(engines.Mannager())
rpc.Daemon()
