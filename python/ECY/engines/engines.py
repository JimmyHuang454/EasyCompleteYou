from loguru import logger
import queue
import importlib
import threading
from ECY import rpc


class Mannager(object):
    """docstring for Mannager"""
    def __init__(self):
        self.current_engine_info = None
        self.engine_dict = {}
        self.InstallEngine('ECY.engines.default_engine')

    def EngineCallbackThread(self, *args):
        engine_info = args[0]
        res_queue = engine_info['res_queue']
        while True:
            try:
                callback_context = res_queue.get()
                event_name = callback_context['event_name']
                callback = getattr(engine_info['engine_obj'],
                                   engine_info[event_name])
                engine_info['res_queue'].put(callback(callback_context))
            except Exception as e:
                logger.exception(e)

    def EngineEventHandler(self, *args):
        engine_info = args[0]
        handler_queue = engine_info['handler_queue']
        while True:
            context = handler_queue.get()
            event_name = context['event_name']
            engine_func = getattr(engine_info['engine'],
                                  engine_info[event_name])
            try:
                callback_context = engine_func(context)
                callback_context['event_name'] = event_name
                engine_info['res_queue'].put(callback_context)
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

        threading.Thread(target=self.EngineCallbackThread,
                         args=(engine_info,),
                         daemon=True).start()

        threading.Thread(target=self.EngineEventHandler,
                         args=(engine_info,),
                         daemon=True).start()

        logger.debug("fuck")
        self.engine_dict[engine_pack_name] = engine_info
        return self.engine_dict[engine_pack_name]

    def _get_engine_obj(self, engine_pack_name):
        if engine_pack_name not in self.engine_dict:
            if self.InstallEngine(engine_pack_name) is False:
                engine_pack_name = 'default_engine'
        return self.engine_dict[engine_pack_name]

    def DoEvent(self, context):
        engine_obj = self._get_engine_obj(context['engine_name'])
        engine_obj['handler_queue'].put({
            'event_name': context['event_name'],
            'context': context
        })

    def BufEnter(self, context):
        path = rpc.DoCall('ECY#utility#GetCurrentBufferPath')
        logger.debug('On BufEnter %s' % (path))
