try:
    from pygments import lex
    from pygments import lexers
    has_pygment = True
except:
    has_pygment = False

from ECY.debug import logger


class Operate(object):
    """
    """
    def __init__(self):
        self.engine_name = 'pygment'
        self.current_lexer = None
        self.cached_items = []

    def OnBufferEnter(self, context):
        params = context['params']
        buffer_path = params['buffer_path']
        self.current_lexer = None
        self.current_lexer = lexers.get_lexer_for_filename(buffer_path,
                                                           stripall=True)
        self._annalysis(context)

    def _annalysis(self, context):
        self.cached_items = []
        params = context['params']
        buffer_content = params['buffer_content']
        buffer_content = '\n'.join(buffer_content)
        items_list = lex(buffer_content, self.current_lexer)

        results_list = []
        for tup in items_list:
            if len(tup[1]) == 1:
                continue
            # the results_format must at least contain the following keys.
            logger.debug(tup)
            results_format = {
                'abbr': '',
                'word': '',
                'kind': '',
                'menu': '',
                'info': '',
                'user_data': ''
            }
            results_format['word'] = tup[1]
            if len(tup[1]) > 30:
                results_format['abbr'] = str(tup[1])[:30]
            else:
                results_format['abbr'] = tup[1]
            results_format['kind'] = str(tup[0])[6:]
            results_list.append(results_format)
        self.cached_items = results_list

    def OnCompletion(self, context):
        context['show_list'] = self.cached_items
        return context

    def OnInsertLeave(self, context):
        self._annalysis(context)
