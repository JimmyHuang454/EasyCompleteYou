from loguru import logger
import queue
import threading
from ECY import rpc


class Mannager(object):
    """docstring for Mannager"""
    def __init__(self):
        self.current_engine_info = None
        self.engine_dict = None

    def EngineCallbackThread(self, engine):
        res_queue = engine['res_queue']
        while True:
            context = res_queue.get()
            event_name = context['event_name']
            callback = getattr(engine['engine'], engine[event_name])
            try:
                engine['res_queue'].put(callback(context))
            except Exception as e:
                logger.exception(e)

    def EngineEventHandler(self, engine):
        handler_queue = engine['handler_queue']
        while True:
            context = handler_queue.get()
            event_name = context['event_name']
            engine_func = getattr(engine['engine'], engine[event_name])
            try:
                engine['res_queue'].put(engine_func())
            except Exception as e:
                logger.exception(e)
                rpc.DoCall('rpc_main#echo', [
                    'Something wrong with [%s] causing ECY can NOT go on, check log info for more.'
                    % (engine['name'])
                ])

    def InstallEngine(self, engine_info):
        engine_info['handler_queue'] = queue.Queue()
        engine_info['res_queue'] = queue.Queue()
        engine_info['engine'] = None

        threading.Thread(target=self.EngineCallbackThread(engine_info),
                         daemon=True).start()

        threading.Thread(target=self.EngineEventHandler(engine_info),
                         daemon=True).start()

        logger.debug(engine_info)

    def CheckInstallEnginesListOK(self):
        if self.engine_dict is None:
            self.engine_dict = rpc.GetVaribal('g:ECY_installed_engines_list')

        if self.engine_dict is None:
            return False
        return True

    def Do(self, event_name):
        if not self.CheckInstallEnginesListOK():
            return
        if self.current_engine_info['name'] not in self.engine_dict:
            self.InstallEngine(self.current_engine_info)

    def BufEnter(self, context):
        path = rpc.DoCall('ECY#utility#GetCurrentBufferPath')
        logger.debug('On BufEnter %s' % (path))
