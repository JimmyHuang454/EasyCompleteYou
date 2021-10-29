# Author: Jimmy Huang (1902161621@qq.com)
# License: WTFPL

import subprocess
import json
import shlex
import queue
import threading
import re
from ECY.debug import logger


class ThreadOfJob(object):
    """keep connection with servers."""
    def __init__(self, thread_id, sub_object, queue_):
        """
        :stdin: is the stdout of server.
        :stdout: is the stdin of server.
        :stderr: the same.
        """
        self.server_id = thread_id
        self._sub_object = sub_object
        self.is_log_stderr = False
        self.__queue = queue_

    def Start(self):
        self._content_size = -1
        self._data_temp = ""
        self._data = ''
        self.get_length = re.compile('Content-Length: ' + '(.*?)' + '\r\n')
        while self.IsServerAlive():
            try:
                self._data_temp = self._read_stdout(self._content_size)
                self._data += self._data_temp
                # the content of data.split should be none, because
                # stdout.readline return when it meet \n
                if self._content_size == -1:
                    headers = self._data.split('\r\n\r\n', 2)
                    # len is 1 when data have no '\r\n\r\n'
                    if len(headers) != 2:
                        # an unkonw erro or
                        # waitting for next buffer to arrived
                        continue
                    content_length = self.get_length.findall(self._data)
                    self._content_size = int(content_length[0])
                    if self._content_size <= 0:
                        # an unkonw erro
                        raise
                else:
                    temp = {'server_id': self.server_id, 'data': self._data}
                    self.__queue.put(temp)
                    # get all of buffer, waitting for next response
                    self._content_size = -1
                self._data = ""
            except:
                pass
                # break

        # child process had been terminated
        if self._sub_object.returncode == 0:
            # TODO
            pass
        else:
            pass

    def LogStderr(self):
        while self.IsServerAlive():
            temp = self._sub_object.stderr.readline()
            temp = str(temp.decode("UTF-8"))
            data = {
                'method': 'window/logMessage',
                'params': {
                    'message': temp,
                    'type': 4
                }
            }
            temp = {'server_id': self.server_id, 'data': json.dumps(data)}
            if self.is_log_stderr:
                self.__queue.put(temp)
        logger.debug("server dead.")

    def IsServerAlive(self):
        if self._sub_object.poll() is None:
            return True
        return False

    def _read_stdout(self, size=-1):

        out_data = None
        if size == -1:
            # return when meet '\n'
            out_data = self._sub_object.stdout.readline()
        else:
            # return when fill in the size of buffer
            out_data = self._sub_object.stdout.read(size)
        out_data = out_data.decode("UTF-8")
        return str(out_data)

    def WriteStdin(self, sending_data):
        self._sub_object.stdin.write(sending_data)
        self._sub_object.stdin.flush()


class Operate:
    """using the standard IO stream to conmunicate with the language
    servers, this class provide the API like vim job's feature,
    including start job with options which contains the callback of
    stdout, stdin, stderr."""
    def __init__(self):
        self.server_info = {}
        self.server_count = 0
        self._queue = queue.Queue()

    def StartJob(self, shell_cmd):
        # can not redect stderr to subprocess.PIPE
        try:
            if type(shell_cmd) == list:
                shell_cmd = " ".join(shell_cmd)
            cmd = shlex.split(shell_cmd)
            # CREATE_NO_WINDOW = 0x08000000
            process_obj = subprocess.Popen(cmd,
                                           shell=True,
                                           stdout=subprocess.PIPE,
                                           stderr=subprocess.PIPE,
                                           stdin=subprocess.PIPE)
            # stderr = subprocess.STDOUT)
            self.server_count += 1

            process_hanlder = ThreadOfJob(self.server_count, process_obj,
                                          self._queue)

            # stdin
            threading.Thread(target=process_hanlder.Start, daemon=True).start()

            # stderr
            threading.Thread(target=process_hanlder.LogStderr,
                             daemon=True).start()

            self.server_info[self.server_count] = {}
            self.server_info[self.server_count]['cmd'] = cmd
            self.server_info[self.server_count]['proc_object'] = process_obj
            self.server_info[
                self.server_count]['thread_object'] = process_hanlder
        except:
            return None
        return self.server_count

    def SendData(self, server_id, data):
        if server_id in self.server_info:
            self.server_info[server_id]['thread_object'].WriteStdin(data)
        else:
            pass

    def PutTodo(self, todo):
        self._queue.put(todo)

    def GetTodo(self, timeout=None):
        if timeout is None:
            return self._queue.get()
        else:
            return self._queue.get(timeout=timeout)

    def GetServerStatus(self, server_id):
        if server_id not in self.server_info:
            # -1 means not existing
            return -1
        try:
            # return None if server have not be terminated
            return self.server_info[self.server_count]['proc_object'].poll()
        except:
            # -2 means unkonw erro
            return -2
