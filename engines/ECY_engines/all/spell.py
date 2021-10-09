import re
from ECY import utils
from ECY.debug import logger

g_spell_checker = utils.InstallPackage('spellchecker')


class Operate(object):
    def __init__(self, engine_name):
        if g_spell_checker is None:
            raise ValueError("Can not find package 'spellchecker'.")
        self.refresh_regex = r'[\-\w+]'
        self.checker = g_spell_checker.SpellChecker()

    def OnCompletion(self, context):
        params = context['params']
        buffer_path = params['buffer_path']
        start_position = params['buffer_position']
        context['regex'] = self.refresh_regex
        context['is_filter'] = False
        current_position_cache = utils.IsNeedToUpdate(context,
                                                      self.refresh_regex)
        if len(current_position_cache['filter_words']) <= 1:
            return

        candidates = self.checker.candidates(
            current_position_cache['filter_words'])

        logger.debug(current_position_cache['filter_words'])

        if len(candidates) == 0:
            return

        self.results_list = []

        for item in candidates:
            results_format = {
                'abbr': '',
                'word': '',
                'kind': '',
                'match_point': [],
                'menu': '',
                'info': '',
                'user_data': ''
            }

            results_format['abbr'] = item + '  '
            results_format['word'] = item
            results_format['kind'] = 'Word'
            self.results_list.append(results_format)

        logger.debug(self.results_list)
        context['show_list'] = self.results_list
        return context
