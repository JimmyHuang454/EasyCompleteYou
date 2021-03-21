from ECY import rpc
from ECY import utils
from ECY.debug import logger
import os


class Operate(object):
    def __init__(self):
        self.workspace_symbol = ['.', '~']
        self.refresh_regex = r'[\.\~\@\$\/\\\w+]'
        self.refresh_regex2 = r'[\.\w+]'
        self.current_position_cache = {}
        self.results_list = []
        self.trigger_key = ['\\', '/']
        self._update_root()

    def _update_root(self):
        self.root_path = rpc.DoCall('ECY#rooter#GetCurrentBufferWorkSpace')

    def try_listdir(self, try_path):
        try:
            return os.listdir(try_path)
        except:
            return []

    def OnBufferEnter(self, context):
        self._update_root()

    def OnCompletion(self, context):
        params = context['params']
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

        try_dir = current_position_cache['prev_string']
        self.results_list = []
        logger.debug(try_dir)

        if len(try_dir) == 0:
            return

        if try_dir[0] in self.workspace_symbol:
            try_dir = self.root_path + try_dir[1:]

        if utils.GetCurrentOS() == 'Windows':
            try_dir = try_dir.replace('\\', '/')

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
            results_format['info'] = try_dir + item

            self.results_list.append(results_format)

        context['show_list'] = self.results_list
        return context
