from loguru import logger
import queue
import sys
import importlib
import threading
from ECY import rpc
from ECY.engines import events_callback
from ECY.engines import events_pre


class Mannager(object):
    """docstring for Mannager"""
    def __init__(self):
        self.current_engine_info = None
        self.engine_dict = {}
        self.default_engine_name = 'ECY.engines.default_engine'
        self.InstallEngine(self.default_engine_name)
        self.events_callback = events_callback.Operate()
        self.events_pre = events_pre.Operate()

    def EngineCallbackThread(self, *args):
        engine_info = args[0]
        res_queue = engine_info['res_queue']
        engine_name = engine_info['name']
        while True:
            try:
                callback_context = res_queue.get()
                event_name = callback_context['event_name']
                self.CallFunction(self.events_callback, event_name,
                                  engine_name, callback_context)
            except Exception as e:
                logger.exception(e)

    def CallFunction(self, obj, method, engine_name, context):
        if not hasattr(obj, method):
            # logger.debug('%s missing function to do %s' %
            #              (engine_name, method))
            return None
        engine_func = getattr(obj, method)
        return engine_func(context)

    def EngineEventHandler(self, *args):
        engine_info = args[0]
        handler_queue = engine_info['handler_queue']
        engine_name = engine_info['name']
        while True:
            context = handler_queue.get()
            event_name = context['event_name']
            try:
                before_context = self.CallFunction(self.events_pre, 'OnRequest',
                                            engine_name, context)

                if before_context is None: # filter this event
                    continue

                if event_name == 'OnCheckEngine':
                    self.CheckEngine(context)
                    continue
                pre_context = self.CallFunction(self.events_pre, event_name,
                                                engine_name, context)
                if pre_context is False:  # filter this event
                    continue
                if pre_context is None:  # has no pre event
                    pre_context = context
                callback_context = self.CallFunction(engine_info['engine_obj'],
                                                     event_name, engine_name,
                                                     pre_context)
                if callback_context is None: # filter this event
                    continue
                engine_info['res_queue'].put(callback_context)
            except Exception as e:
                logger.exception(e)
                rpc.DoCall('ECY#utils#echo', [
                    'Something wrong with [%s] causing ECY can NOT go on, check log info for more.'
                    % (engine_name)
                ])

    def InstallEngine(self, engine_pack_name):
        engine_info = {}
        try:
            if type(engine_pack_name) is dict:
                sys.path.append(engine_pack_name['dir'])
                module_obj = importlib.import_module(engine_pack_name['name'])
            else:
                module_obj = importlib.import_module(engine_pack_name)
            engine_info['engine_obj'] = module_obj.Operate()
        except Exception as e:
            logger.exception(e)
            # rpc.DoCall('rpc_main#echo', [
            #     'Failed to install [%s], check log info for more.' %
            #     (engine_pack_name)
            # ])
            return False
        engine_info['handler_queue'] = queue.Queue()
        engine_info['res_queue'] = queue.Queue()
        engine_info['name'] = engine_pack_name

        threading.Thread(target=self.EngineCallbackThread,
                         args=(engine_info, ),
                         daemon=True).start()

        threading.Thread(target=self.EngineEventHandler,
                         args=(engine_info, ),
                         daemon=True).start()

        logger.debug("installed engine %s" % (engine_info))
        self.engine_dict[engine_pack_name] = engine_info
        return self.engine_dict[engine_pack_name]

    def _get_engine_obj(self, engine_pack_name):
        if engine_pack_name not in self.engine_dict:
            if self.InstallEngine(engine_pack_name) is False:
                return self._get_default_engine()
        return self.engine_dict[engine_pack_name]

    def _get_default_engine(self):
        return self.engine_dict[self.default_engine_name]

    def DoEvent(self, context):
        engine_obj = self._get_engine_obj(context['engine_name'])
        context['engine_name'] = engine_obj['name']
        engine_obj['handler_queue'].put(context)

    def CheckEngine(self, context):
        params = context['params']
        to_be_check_engine_list = params['engine_list']
        res = {}
        for item in to_be_check_engine_list:
            temp = self._get_engine_obj(item)
            if temp == self.default_engine_name:
                res[item] = [
                    '{Error} Engine not exists or having critical errors.'
                ]
            else:
                check_res = self.CallFunction(temp, 'Check', item, context)
                if check_res is None:
                    res[item] = ['{Warning} Has no check function.']
                elif 'res' not in check_res or type(
                        check_res['res']) is not list:
                    res[item] = ["{Error} ECY can NOT parse engine's return."]
                else:
                    res[item] = check_res['res']

        returns = []
        i = 0
        for item in res:
            returns.append('%s. Engine name: [%s] \n' % (str(i), item))
            returns.extend(res[item])
            returns.append('\n')
            i += 1
        rpc.DoCall('ECY#utils#show', [returns, 'buffer', 'ECY_check'])
