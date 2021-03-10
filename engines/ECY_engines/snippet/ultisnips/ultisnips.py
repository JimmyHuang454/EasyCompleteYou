from ECY import rpc


class Operate(object):
    """
    """
    def __init__(self):
        self.engine_name = 'ultisnipts'
        self.snippet_cache = {}

    def _update_snippets(self, context):
        if 'file_type' in context:
            file_type = context['file_type']
        else:
            file_type = rpc.DoCall('ECY#utils#GetCurrentBufferFileType')

        if file_type in self.snippet_cache:
            return

        try:
            rpc.DoCall('UltiSnips#SnippetsInCurrentScope', [1])
            snippets = rpc.GetVaribal('g:current_ulti_dict_info')
        except:
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

        self.snippet_cache[file_type] = results_list

    def OnBufferEnter(self, context):
        self._update_snippets(context)

    def OnCompletion(self, context):
        file_type = rpc.DoCall('ECY#utils#GetCurrentBufferFileType')
        context['file_type'] = file_type
        self._update_snippets(context)
        if file_type not in self.snippet_cache:
            return
        context['show_list'] = self.snippet_cache[file_type]
        return context
