from loguru import logger
import queue
import importlib
import threading
from ECY import rpc


class Mannager(object):
    """docstring for Mannager"""
    def __init__(self):
        self.current_engine_info = None
        self.engine_dict = None

    def EngineCallbackThread(self, engine_info):
        res_queue = engine_info['res_queue']
        while True:
            try:
                context = res_queue.get(timeout=5)
                event_name = context['event_name']
                callback = getattr(engine_info['engine_obj'],
                                   engine_info[event_name])
                engine_info['res_queue'].put(callback(context))
            except Exception as e:
                logger.exception(e)

    def EngineEventHandler(self, engine_info):
        handler_queue = engine_info['handler_queue']
        while True:
            context = handler_queue.get()
            event_name = context['event_name']
            engine_func = getattr(engine_info['engine'],
                                  engine_info[event_name])
            try:
                # engine_info['res_queue'].put(engine_func())
                engine_func()
            except Exception as e:
                logger.exception(e)
                rpc.DoCall('rpc_main#echo', [
                    'Something wrong with [%s] causing ECY can NOT go on, check log info for more.'
                    % (engine_info['name'])
                ])

    def InstallEngine(self, engine_pack_name):
        engine_info = {}
        try:
            module_obj = importlib.import_module(engine_pack_name)
            engine_info['engine_obj'] = module_obj.Operate()
        except Exception as e:
            logger.exception(e)
            rpc.DoCall('rpc_main#echo', [
                'Failed to install [%s], check log info for more.' %
                (engine_info['name'])
            ])
            return False
        engine_info['handler_queue'] = queue.Queue()
        engine_info['res_queue'] = queue.Queue()

        threading.Thread(target=self.EngineCallbackThread(engine_info),
                         daemon=True).start()

        threading.Thread(target=self.EngineEventHandler(engine_info),
                         daemon=True).start()

        logger.debug(engine_info)
        self.engine_dict[engine_pack_name] = engine_info
        return self.engine_dict[engine_pack_name]

    def _get_engine_obj(self):
        engine_pack_name = rpc.GetVaribal('g:ECY_current_buffer_engine_name')
        if engine_pack_name not in self.engine_dict:
            if self.InstallEngine(engine_pack_name) is False:
                # using default engine
                engine_pack_name = 'Label'
        return self.engine_dict[engine_pack_name]

    def DoEvent(self, context):
        engine_obj = self._get_engine_obj()
        engine_obj['handler_queue'].put({
            'event_name': context['context'],
            'context': context
        })

    def BufEnter(self, context):
        path = rpc.DoCall('ECY#utility#GetCurrentBufferPath')
        logger.debug('On BufEnter %s' % (path))
