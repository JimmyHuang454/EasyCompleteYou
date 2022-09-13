from ECY import rpc


class Operate(object):
    """
    """
    def __init__(self, engine_name=None):
        self.snippet_cache = {}

    def _update_snippets(self, context):
        if 'filetype' in context:
            filetype = context['filetype']
        else:
            filetype = rpc.DoCall('ECY#utils#GetCurrentBufferFileType')

        if filetype in self.snippet_cache:
            return

        snippets = rpc.DoCall('ECY#utils#GetUltiSnippets')

        if snippets == {}:
            return

        results_list = []
        for trigger, snippet in snippets.items():
            results_format = {
                'abbr': '',
                'word': '',
                'kind': '',
                'menu': '',
                'info': '',
                'user_data': ''
            }
            results_format['word'] = trigger
            results_format['abbr'] = trigger
            results_format['kind'] = '[Snippet]'
            description = snippet['description']
            if not description == '':
                results_format['menu'] = description
            results_list.append(results_format)

        self.snippet_cache[filetype] = results_list

    def OnBufferEnter(self, context):
        self._update_snippets(context)

    def OnCompletion(self, context):
        filetype = rpc.DoCall('ECY#utils#GetCurrentBufferFileType')
        context['filetype'] = filetype
        self._update_snippets(context)
        if filetype not in self.snippet_cache:
            return
        context['show_list'] = self.snippet_cache[filetype]
        return context
