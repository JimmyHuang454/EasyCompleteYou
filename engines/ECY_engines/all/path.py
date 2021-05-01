from ECY import rpc
from ECY import utils
from ECY.debug import logger
import os
import re


class Operate(object):
    def __init__(self):
        self.workspace_symbol = ['@', '~']
        self.refresh_regex = r'[\.\~\-\@\$\/\\\w+]'
        self.refresh_regex2 = r'[\.\-\w+]'
        self.current_position_cache = {}
        self.results_list = []
        self.trigger_key = ['\\', '/']
        self._update_root()

    def _update_root(self, context=None):
        self.root_path = rpc.DoCall('ECY#rooter#GetCurrentBufferWorkSpace')
        self.root_path = self.root_path.replace('\\', '/')
        if context is None:
            return
        try:
            self.exists_regex = []
            buffer_path = context['params']['buffer_path']
            while True:
                temp = os.path.dirname(buffer_path)
                if buffer_path == temp:
                    break
                buffer_path = temp
                temp = buffer_path + '/.gitignore'
                if os.path.exists(temp):
                    with open(temp, encoding="utf8") as f:
                        for item in f.read().split('\n'):
                            if item == '':
                                continue
                            self.exists_regex.append(item)
                    break
            logger.debug(self.exists_regex)
        except:
            pass

    def _apply_ignore(self, item):
        for regexs in self.exists_regex:
            try:
                if re.match(regexs, item) is not None:
                    return True
            except:
                return False
        return False

    def try_listdir(self, try_path):
        try:
            res = []
            for item in os.listdir(try_path):
                if self._apply_ignore(item):
                    continue
                res.append(item)
            return res
        except Exception as e:
            logger.exception(e)
            return []

    def OnBufferEnter(self, context):
        self._update_root(context)

    def _handle_dot(self, try_path, root):
        root = os.path.dirname(root)
        temp = try_path

        if temp[:2] == './':
            return root + '/'
        up_counts = 0
        try:
            while True:
                if temp[:3] != '../':
                    break
                temp = temp[3:]
                up_counts += 1
                root = os.path.dirname(root)
        except:
            pass
        if up_counts != 0:
            return root + '/' + temp
        return try_path

    def OnCompletion(self, context):
        params = context['params']
        buffer_path = params['buffer_path']
        start_position = params['buffer_position']
        context['show_list'] = self.results_list
        context['trigger_key'] = self.trigger_key
        context['regex'] = self.refresh_regex2

        current_position_cache = utils.IsNeedToUpdate(context,
                                                      self.refresh_regex2)

        # not_filter_strings = current_position_cache['prev_string']

        current_start_postion = {
            'line': start_position['line'],
            'character': current_position_cache['current_colum']
        }

        if current_start_postion == self.current_position_cache:
            return context

        self.current_position_cache = current_start_postion

        temp = context['params']['buffer_position']['colum']
        context['params']['buffer_position']['colum'] = current_position_cache[
            'current_colum']

        current_position_cache = utils.IsNeedToUpdate(context,
                                                      self.refresh_regex)

        context['params']['buffer_position']['colum'] = temp

        try_dir = current_position_cache['filter_words']
        self.results_list = []
        logger.debug(try_dir)

        if len(try_dir) == 0:
            return

        if utils.GetCurrentOS() == 'Windows':
            try_dir = try_dir.replace('\\', '/')

        if try_dir[0] in self.workspace_symbol:
            try_dir = self.root_path + try_dir[1:]
        elif try_dir[0] == '.':
            try_dir = self._handle_dot(try_dir, buffer_path)

        logger.debug(try_dir)
        dir_list = self.try_listdir(try_dir)
        for item in dir_list:
            results_format = {
                'abbr': '',
                'word': '',
                'kind': '',
                'menu': '',
                'info': '',
                'user_data': ''
            }

            item_name = item

            results_format['abbr'] = item_name
            results_format['word'] = item_name
            path = try_dir + item
            if os.path.isdir(path):
                results_format['kind'] = '[Dir]'
            elif os.path.isfile(path):
                results_format['kind'] = '[File]'
            elif os.path.isabs(path):
                results_format['kind'] = '[Abs]'
            elif os.path.islink(path):
                results_format['kind'] = '[Link]'
            results_format['info'] = path
            self.results_list.append(results_format)

        context['show_list'] = self.results_list

        return context
