# -*- coding: UTF-8 -*-
from loguru import logger
import json
import threading
import io
import sys
import queue


def Send(types, function_name='', variable_name='', params=[]):
    global request_id
    global request_list
    request_id += 1
    cmd = {
        'type': types,
        'params': params,
        'function_name': function_name,
        'variable_name': variable_name,
        'id': request_id
    }
    request_list[request_id] = {'cmd': cmd, 'res_queue': queue.Queue()}
    print(json.dumps(cmd), flush=True)  # with "\n"
    context = request_list[request_id]['res_queue'].get(
        timeout=5)  # block here
    if context['status'] != 0:
        logger.error(context)
    del request_list[request_id]
    return context['res']


def EventHandler():
    global blind_event_instance
    global g_event_handle_thread
    while True:
        try:
            context = g_event_handle_thread.get()
            blind_event_instance.DoEvent(context)
        except Exception as e:
            raise e


@logger.catch
def DoCall(function_name, params=[]):
    return Send('call', function_name=function_name, params=params)


@logger.catch
def GetVaribal(variable_name):
    return Send('get', variable_name=variable_name)


def WriteStdOut():
    return sys.stdin.write()


def ReadStdIn():
    return sys.stdin.readline()


def FallBack():
    global g_event_handle_thread
    content2 = ''
    logger.debug('Started RPC')
    while True:
        try:
            content = ReadStdIn()
            content2 = content2 + content
            content_split = content2.split('\n')
            lens = len(content_split)
            if lens == 1:
                continue
            else:
                content2 = content_split[lens - 1]
            i = 0
            while i < (lens - 1):
                if content_split[i] == '':
                    continue
                context = json.loads(content_split[i], encoding='utf-8')
                if context['type'] == 'event':
                    g_event_handle_thread.put(context)
                elif context['type'] == 'fallback':
                    re_id = context['request_id']
                    if re_id not in request_list:
                        continue
                    request_list[re_id]['res_queue'].put(context)
                else:
                    pass
                i += 1
        except Exception as e:
            logger.exception(e)
            raise


def Daemon():  # start, call once
    global request_id
    global g_event_handle_thread
    request_id = 0
    g_event_handle_thread = queue.Queue()

    global request_list
    request_list = {}
    sys.stdin = io.TextIOWrapper(sys.stdin.buffer, encoding='utf-8')
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')
    threading.Thread(target=EventHandler, daemon=True).start()
    FallBack()  # blcok here


def BlindEvent(classs):
    global blind_event_instance
    blind_event_instance = classs
    logger.debug('BlindEvent')
