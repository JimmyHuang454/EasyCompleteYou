# -*- coding: UTF-8 -*-
import json
import io
import time
import sys
import threading
import queue
from loguru import logger


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
    json_dict = request_list[request_id]['res_queue'].get(
        timeout=5)  # block here
    del request_list[request_id]
    return json_dict['res']


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


def EventThread():
    global g_event_handle_thread
    logger.debug('lisenting EventThread()')
    while True:
        event = g_event_handle_thread.get()
        NotifyEvent(event['event_name'])


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
                json_dict = json.loads(content_split[i], encoding='utf-8')
                if json_dict['type'] == 'event':
                    g_event_handle_thread.put(json_dict)
                elif json_dict['type'] == 'fallback':
                    re_id = json_dict['request_id']
                    if re_id not in request_list:
                        continue
                    request_list[re_id]['res_queue'].put(json_dict)
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
    threading.Thread(target=EventThread, daemon=True).start()
    FallBack()  # blcok here


def BlindEvent(classs):
    global blind_event_instance
    blind_event_instance = classs


def NotifyEvent(event_name):
    global blind_event_instance
    if not hasattr(blind_event_instance, event_name):
        return
    temp = getattr(blind_event_instance, event_name)
    try:
        temp()
    except Exception as e:
        logger.exception(e)
