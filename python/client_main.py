# -*- coding: UTF-8 -*-
from loguru import logger
from ECY import rpc
import ECY.engines.engines as engines

logger.add(
    "C:/Users/qwer/Desktop/vimrc/myproject/ECY/RPC/EasyCompleteYou/ECY_Debug_log/{time}.log",
    level="DEBUG")

rpc.BlindEvent(engines.Mannager())
rpc.Daemon()
