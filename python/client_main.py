# -*- coding: UTF-8 -*-
from loguru import logger
from ECY import rpc
import ECY.engines.engines as engines
import sys

path = "C:/Users/qwer/Desktop/vimrc/myproject/ECY/RPC/EasyCompleteYou/ECY_Debug_log/ECY_debug.log"

sys.path.append('C:/Users/qwer/Desktop/vimrc/myproject/ECY/RPC/EasyCompleteYou/engines')

logger.remove()
with open(path, 'w', encoding='utf-8') as f:
    f.write('')

level = "DEBUG"
# level = "CRITICAL"
logger.add(path, level=level, encoding='utf-8')

rpc.BlindEvent(engines.Mannager())
rpc.Daemon()
