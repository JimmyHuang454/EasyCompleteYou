# Author: Jimmy Huang (1902161621@qq.com)
# License: WTFPL

import os
import queue
import threading
import time

from ECY import utils
from ECY import rpc
from ECY.debug import logger

try:
    import jedi
    has_jedi = True
except:
    has_jedi = False
try:
    from pyflakes import api as pyflakes_api, messages
    PYFLAKES_ERROR_MESSAGES = (
        messages.UndefinedName,
        messages.UndefinedExport,
        messages.UndefinedLocal,
        messages.DuplicateArgument,
        messages.FutureFeatureNotDefined,
        messages.ReturnOutsideFunction,
        messages.YieldOutsideFunction,
        messages.ContinueOutsideLoop,
        messages.BreakOutsideLoop,
        messages.ContinueInFinally,
        messages.TwoStarredExpressions,
    )
    has_pyflake = True
except:
    has_pyflake = False


class Operate():
    def __init__(self):
        # a jedi bug:
        # check https://github.com/davidhalter/jedi-vim/issues/870
        # revert to 0.9 of jedi can fix this

        # FIXME:when completing the last line of a method or a class will
        # show only a few of items, mabye, because the cache's system position
        # don't match with jedi
        # revert to 0.9 of jedi can also fix this
        self.engine_name = 'ECY_engines.python.jedi.jedi'
        self._jedi_cache = {
            'src': '',
            'current_line': 0,
            'current_colum': 0,
            'line_counts': 0
        }
        self._using_jedi_env = {
            'auto': None,
            'force': None,
            'force_version': None
        }
        self.trigger_key = ['.', '>', ':', '*']

        if has_pyflake:
            self._diagnosis_queue = queue.LifoQueue()
            threading.Thread(target=self._handle_diagnosis).start()

    def _diagnosis(self, context):
        if not has_pyflake:
            return
        self._diagnosis_queue.put(context)

    def _GetJediScript(self, context):
        try:
            params = context['params']
            path = params['buffer_path']
            line_nr = params['buffer_position']['line'] + 1
            line_text = params['buffer_content']
            line_text = "\n".join(params['buffer_content'])
            current_colum = params['buffer_position']['colum']
            temp = jedi.Script(line_text, line_nr, current_colum, path)
            # environment=self._get_environment(context['ForceVersion']))
            return temp
        except:
            return []

    def _get_auto_env(self):
        if self._using_jedi_env['auto'] is None:
            self._using_jedi_env['auto'] = \
                    jedi.api.environment.get_cached_default_environment()
        return self._using_jedi_env['auto']

    def _get_environment(self, force_to_use):
        if force_to_use == 'auto':
            return self._get_auto_env()

        force_python_version = force_to_use
        if self._using_jedi_env['force_version'] is not None \
                and self._using_jedi_env['force'] == force_to_use:
            # cached
            return self._using_jedi_env['force_version']

        # reflesh
        self._using_jedi_env['force'] = force_to_use
        if '0000' in force_python_version or '9999' in force_python_version:
            # It's probably a float that wasn't shortened.
            try:
                force_python_version = "{:.1f}".format(
                    float(force_python_version))
            except ValueError:
                pass
        elif isinstance(force_python_version, float):
            force_python_version = "{:.1f}".format(force_python_version)

        try:
            environment = jedi.get_system_environment(force_python_version)
            self._using_jedi_env['force_version'] = environment
        except jedi.InvalidPythonEnvironment:
            self._using_jedi_env['force_version'] = None
            return self._get_auto_env()

    def _analyze_params(self, line, show_default_value=False):
        # {{{

        # remove the first (, the last ) and the func name
        i = 0
        j = 0
        start = 0
        end = 0
        for item in line:
            if item == '(':
                if i == 0:
                    start = j
                i += 1
            elif item == ')':
                i -= 1
                end = j
                if i == 0:
                    break
            j += 1
        line = line[start + 1:end] + ','

        i = 0
        j = 0
        temp = ''
        params = []
        for item in line:
            if item == '(':
                i += 1
                temp += '('
                continue
            elif item == ')':
                j += 1
                temp += ')'
                continue
            if item != ',':
                if item in ['\\', ' ', '/', '\n']:
                    pass
                else:
                    temp += item
            else:
                depth = i - j
                if depth != 0:
                    temp += item
                else:
                    if temp != '' and temp not in ['self', 'cls']:
                        # remove cls and self

                        has_default_value = False
                        if not show_default_value:
                            for litter in temp:
                                if litter in ['=']:
                                    has_default_value = True
                                    break
                        if not has_default_value:
                            params.append(temp)
                    temp = ''
        return params

    # }}}

    def _build_func_snippet(self, name, params, using_PEP8=True):
        # {{{
        if len(params) == 0:
            snippet = str(name) + '($1)$0'
        else:
            j = 0
            snippet = str(name) + '('
            for item in params:
                j += 1
                if j == len(params):
                    temp = '${' + str(j) + ':' + str(item) + '}'
                else:
                    temp = '${' + str(j) + ':' + str(item) + '}, '
                snippet += temp
            snippet += ')${0}'
        return snippet

    # }}}

    def _is_comment(self, current_line, column):
        i = 0
        for word in current_line[:column]:
            if word in ['#']:
                if self.IsInsideQuotation(current_line, i):
                    return False
                return True
            i += 1
        return False

    def IsInsideQuotation(self, current_line, column):
        # {{{
        if column == 0 or len(current_line) > 1000:
            return False
        if len(current_line) > 1000:
            return True
        after = current_line[column:]
        pre = current_line[:column]
        pre_i = 0
        pre_j = 0
        after_i = 0
        after_j = 0
        for word in pre:
            if word in ['\"']:
                pre_i += 1
            elif word in ['\'']:
                pre_j += 1

        for word in after:
            if word in ['\"']:
                after_i += 1
            elif word in ['\'']:
                after_j += 1

        if pre_i != 0 and after_i != 0:
            if pre_i % 2 != 0 and after_i % 2 != 0:
                return True
        if pre_j != 0 and after_j != 0:
            if pre_j % 2 != 0 and after_j % 2 != 0:
                return True
        return False
        # }}}

    def _is_need_to_update(self, context, regex):
        params = context['params']
        current_colum = params['buffer_position']['colum']
        # current_line = params['buffer_position']['line']
        current_line_content = params['buffer_position']['line_content']
        temp = bytes(current_line_content, encoding='utf-8')
        prev_key = str(temp[:current_colum], encoding='utf-8')

        return utils.MatchFilterKeys(prev_key, regex)

    def OnCompletion(self, context):
        # {{{
        context['trigger_key'] = self.trigger_key
        params = context['params']
        current_colum = params['buffer_position']['colum']
        current_line = params['buffer_position']['line']
        current_line_content = params['buffer_position']['line_content']
        if self.IsInsideQuotation(current_line_content, current_colum)\
                or self._is_comment(current_line_content, current_colum):
            context['show_list'] = []
            return context

        regex = r'[\w+]'
        temp = bytes(current_line_content, encoding='utf-8')
        context['prev_key'] = str(temp[:current_colum], encoding='utf-8')
        current_colum, filter_words, last_key = utils.MatchFilterKeys(
            context['prev_key'], regex)

        content_len = len(params['buffer_content'])
        if current_line != self._jedi_cache[
                'current_line'] or current_colum != self._jedi_cache[
                    'current_colum'] or self._jedi_cache[
                        'line_counts'] != content_len:
            # sometimes, jedi will fail, so we try.
            try:
                src = self._GetJediScript(context).completions()
            except:
                src = []

            if len(src) == 0:
                context['show_list'] = []
                return context

            results_list = []
            for item in src:
                results_format = {
                    'abbr': '',
                    'word': '',
                    'kind': '',
                    'menu': '',
                    'info': '',
                    'user_data': ''
                }
                results_format['abbr'] = item.name_with_symbols
                results_format['word'] = item.name

                temp = item.type
                temp = temp[0].upper() + temp[1:]
                temp = str(temp)
                results_format['kind'] = temp

                results_format['menu'] = item.description
                temp = item.docstring()
                results_format['info'] = temp.split("\n")
                try:
                    if item.type in ['function', 'class']:
                        params = self._analyze_params(temp)
                        snippet = self._build_func_snippet(item.name, params)
                        results_format['snippet'] = snippet
                        results_format['kind'] += '~'
                except:
                    pass
                results_list.append(results_format)

            self._jedi_cache = {
                'src': results_list,
                'current_line': current_line,
                'current_colum': current_colum,
                'line_counts': content_len
            }
        else:
            results_list = self._jedi_cache['src']

        context['show_list'] = results_list
        return context
        # }}}

    def GetSymbol(self, version):
        """ document symbols
        """
        return_ = {'ID': version['VersionID']}
        try:
            # in embed python, some of this can not find module path.
            # So we try
            definitions = jedi.api.names(source=version['AllTextList'],
                                         all_scopes=True,
                                         definitions=True,
                                         references=False,
                                         path=version['FilePath'])
        except:
            definitions = []
        lists = []
        for item in definitions:
            position = item._name.tree_name.get_definition()
            # start_column is 0-based
            (start_line, start_column) = position.start_pos
            items = [{
                'name': '1',
                'content': {
                    'abbr': item.name
                }
            }, {
                'name': '2',
                'content': {
                    'abbr': item.type
                }
            }, {
                'name': '3',
                'content': {
                    'abbr': str(position.start_pos)
                }
            }]
            position = {
                'line': start_line,
                'colum': start_column,
                'path': version['FilePath']
            }
            temp = {'items': items, 'type': 'symbol', 'position': position}
            lists.append(temp)
        return_['Results'] = lists
        return return_

    def OnBufferEnter(self, context):
        self._diagnosis(context)

    def OnTextChanged(self, context):
        self._diagnosis(context)

    def OnDocumentHelp(self, version):
        try:
            definitions = self._GetJediScript(version).goto_definitions()
        except:
            definitions = None
        return_ = {'ID': version['VersionID'], 'Results': []}
        docs = []
        if not definitions:
            return return_

        for d in definitions:
            doc = d.docstring()
            if doc:
                title = 'Docstring for %s' % d.desc_with_module
                underline = '-' * 20
                # underline = '-' * len(title)
                docs.append(title)
                docs.append(underline)
                docs.extend(doc.split("\n"))
                docs.append('')
        return_['Results'] = docs
        return return_

    def Goto(self, version):
        return_ = {'ID': version['VersionID']}
        result_lists = []
        for item in version['GotoLists']:
            try:
                # in embed python, some of this can not find module path.
                # So we try
                if item == 'definition':
                    result_lists = self._goto_definition(version, result_lists)
                if item == 'declaration':
                    result_lists = self._goto_declaration(
                        version, result_lists)
                if item == 'references':
                    result_lists = self._goto_reference(version, result_lists)
            except:
                pass
                # will return []
        return_['Results'] = result_lists
        return return_

    def _goto_definition(self, version, results):
        # can return mutiple definitions
        definitions = self._GetJediScript(version).goto_definitions()
        return self._build_goto(definitions, results, 'goto_definitions')

    def _goto_declaration(self, version, results):
        assisment = self._GetJediScript(version).goto_assignments()
        return self._build_goto(assisment, results, 'goto_declaration')

    def _goto_reference(self, version, results):
        usages = self._GetJediScript(version).usages()
        return self._build_goto(usages, results, 'goto_reference')

    def _build_goto(self, goto_sources, results, kind):
        for item in goto_sources:
            if item.in_builtin_module():
                path = " "
                file_size = " "
                pos = 'Buildin'
                position = {}
            else:
                path = str(item.module_path)
                file_size = str(int(os.path.getsize(path) / 1000)) + 'KB'
                pos = '[' + str(item.line) + ', ' + str(item.column) + ']'
                position = {
                    'line': item.line,
                    'colum': item.column,
                    'path': path
                }

            items = [{
                'name': '1',
                'content': {
                    'abbr': item.description
                }
            }, {
                'name': '2',
                'content': {
                    'abbr': kind
                }
            }, {
                'name': '3',
                'content': {
                    'abbr': pos
                }
            }, {
                'name': '4',
                'content': {
                    'abbr': path
                }
            }, {
                'name': '5',
                'content': {
                    'abbr': file_size
                }
            }]

            temp = {'items': items, 'type': kind, 'position': position}
            results.append(temp)
        return results

    def _handle_diagnosis(self):
        reporter = PyflakesDiagnosticReport('')
        self.document_id = -1
        while 1:
            try:
                context = self._diagnosis_queue.get()
                params = context['params']
                if params['buffer_id'] <= self.document_id:
                    continue
                self.document_id = params['buffer_id']
                text_string = '\n'.join(params['buffer_content'])
                reporter.SetContent(text_string)
                pyflakes_api.check(text_string,
                                   params['buffer_path'],
                                   reporter=reporter)
                res = reporter.GetDiagnosis()
                rpc.DoCall('ECY#diagnostics#PlaceSign', [{
                    'engine_name': self.engine_name,
                    'res_list': res
                }])
                time.sleep(1)
            except Exception as e:
                logger.exception(e)
                break


class PyflakesDiagnosticReport(object):
    def __init__(self, _):
        self.lines = ''
        self.results_list = []

    def GetDiagnosis(self):
        return self.results_list

    def SetContent(self, lines):
        self.lines = lines
        self.results_list = []

    def unexpectedError(self, file_path, msg):  # pragma: no cover
        position = {
            'line': 1,
            'range': {
                'start': {
                    'line': 1,
                    'colum': 0
                },
                'end': {
                    'line': 1,
                    'colum': 0
                }
            }
        }
        diagnosis = 'unexpected Error'
        pos_string = '[1, 0]'
        kind = 1
        kind_name = 'unexpectedError'
        temp = [{
            'name': '1',
            'content': {
                'abbr': diagnosis
            }
        }, {
            'name': '2',
            'content': {
                'abbr': kind_name
            }
        }, {
            'name': '3',
            'content': {
                'abbr': file_path
            }
        }, {
            'name': '4',
            'content': {
                'abbr': pos_string
            }
        }]
        temp = {
            'items': temp,
            'type': 'diagnosis',
            'file_path': file_path,
            'kind': kind,
            'diagnostics': diagnosis,
            'position': position
        }
        self.results_list.append(temp)

    def _genarate_position(self, line, colum):
        return '[' + str(line) + ', ' + str(colum) + ']'

    def syntaxError(self, file_path, diagnosis, lineno, offset, text):
        # We've seen that lineno and offset can sometimes be None
        lineno = lineno or 1
        offset = offset or 0

        erro_line_nr = lineno
        position = {
            'line': erro_line_nr,
            'range': {
                'start': {
                    'line': erro_line_nr,
                    'colum': offset
                },
                'end': {
                    'line': erro_line_nr,
                    'colum': offset + len(text)
                }
            }
        }
        pos_string = self._genarate_position(erro_line_nr, offset)
        kind = 1
        kind_name = 'syntaxError1'
        temp = [{
            'name': '1',
            'content': {
                'abbr': diagnosis
            }
        }, {
            'name': '2',
            'content': {
                'abbr': kind_name
            }
        }, {
            'name': '3',
            'content': {
                'abbr': file_path
            }
        }, {
            'name': '4',
            'content': {
                'abbr': pos_string
            }
        }]

        temp = {
            'items': temp,
            'type': 'diagnosis',
            'file_path': file_path,
            'kind': kind,
            'diagnostics': diagnosis,
            'position': position
        }
        self.results_list.append(temp)

    def flake(self, message):
        """ Get message like <filename>:<lineno>: <msg> """
        # 0-based
        erro_line_nr = message.lineno
        position = {
            'line': erro_line_nr,
            'range': {
                'start': {
                    'line': erro_line_nr,
                    'colum': message.col
                },
                'end': {
                    'line': erro_line_nr,
                    'colum': message.col
                }
            }
        }
        pos_string = self._genarate_position(erro_line_nr, message.col)

        kind_name = 'syntaxWarning'
        kind = 2
        diagnosis = message.message % message.message_args
        file_path = message.filename
        for message_type in PYFLAKES_ERROR_MESSAGES:
            if isinstance(message, message_type):
                kind_name = 'syntaxError2'
                kind = 1
                break
        temp = [{
            'name': '1',
            'content': {
                'abbr': diagnosis
            }
        }, {
            'name': '2',
            'content': {
                'abbr': kind_name
            }
        }, {
            'name': '3',
            'content': {
                'abbr': file_path
            }
        }, {
            'name': '4',
            'content': {
                'abbr': pos_string
            }
        }]

        temp = {
            'items': temp,
            'type': 'diagnosis',
            'file_path': file_path,
            'kind': kind,
            'diagnostics': diagnosis,
            'position': position
        }
        self.results_list.append(temp)
