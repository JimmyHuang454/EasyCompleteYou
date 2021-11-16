from ECY_engines import lsp
from ECY import rpc
from ECY_engines.snippet.ultisnips import ultisnips
from ECY import utils


class Operate(lsp.Operate):
    def __init__(self, engine_name):
        lsp.Operate.__init__(self,
                             engine_name,
                             refresh_regex=r'[\w+\-]',
                             languageId='html')
        self.snip = ultisnips.Operate()

    def OnBufferEnter(self, context):
        super().OnBufferEnter(context)
        self.snip.OnBufferEnter(context)

    def OnCompletion(self, context):
        context = super().OnCompletion(context)
        if context is None:
            return  # server not supports.

        show_list = []
        for item in context['show_list']:
            results_format = {
                'abbr': '',
                'word': '',
                'kind': '',
                'menu': '',
                'info': '',
                'user_data': ''
            }

            if 'kind' in item:
                results_format['kind'] = self._lsp.GetKindNameByNumber(
                    item['kind'])
            else:
                results_format['kind'] = 'Unknow'

            item_name = item['label']

            results_format['abbr'] = item_name
            results_format['word'] = item_name

            detail = []
            if 'detail' in item:
                detail = item['detail'].split('\n')
                results_format['menu'] = item['detail']

            document = []

            if 'insertTextFormat' in item:
                insertTextFormat = item['insertTextFormat']
                if insertTextFormat == 2:
                    snippet = None
                    if 'textEdit' in item:
                        snippet = item['textEdit']
                        snippet = snippet['newText']
                    elif 'insertText' in item:
                        snippet = item['insertText']

                    if snippet is not None:
                        results_format['snippet'] = snippet
                        results_format['kind'] += '~'

            if 'documentation' in item:
                if type(item['documentation']) is str:
                    temp = item['documentation'].split('\n')
                elif type(item['documentation']) is dict:
                    temp = item['documentation']['value'].split('\n')

                document.extend(temp)

            results_format['info'] = '\n'.join(document)
            show_list.append(results_format)
        context['show_list'] = show_list
        return context
