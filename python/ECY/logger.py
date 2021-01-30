import os
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
print(BASE_DIR)
print(__file__)

global g_is_debug

g_is_debug = True

try:
    import snoop
    has_snoop = True
    snoop.install(
        enabled=g_is_debug,
        out=
        "C:/Users/qwer/Desktop/vimrc/myproject/ECY/EasyCompleteYou/rpc/rpc.log"
    )
except:
    has_snoop = False
