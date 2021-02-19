# Author: Jimmy Huang (1902161621@qq.com)
# License: WTFPL

#!/usr/bin/env python
# -*- coding: utf-8 -*-

import vim
import os
import os.path

from leaderf.utils import *
from leaderf.explorer import *
from leaderf.manager import *

# *****************************************************
# ECYDiagnosisExplorer
# *****************************************************


class ECYDiagnosisExplorer(Explorer):
    def __init__(self):
        pass

    def getContent(self, *args, **kwargs):
        # return a list
        global g_items_data
        global g_callback_name
        g_items_data = lfEval("g:ECY_items_data")
        g_callback_name = lfEval("g:ECY_selecting_cb_name")
        # max length
        items_len = {}
        for item in g_items_data:
            for line in item['items']:
                name = line['name']
                length = len(line['content']['abbr'])
                if name not in items_len.keys():
                    items_len[name] = 0
                if length > items_len[name]:
                    items_len[name] = length + 2

        results = []
        j = 0
        for item in g_items_data:
            temp = ""
            k = 0
            for line in item['items']:
                abbr = line['content']['abbr']
                name = line['name']
                i = 0
                to_be_add = ""
                while i < items_len[name] - len(abbr):
                    to_be_add += " "
                    i += 1
                abbr += to_be_add
                abbr = abbr.replace('|', '\\')
                if k == 0:
                    abbr += "| "
                temp += abbr
                k += 1
            temp += " " + str(j)
            results.append(temp)
            j += 1
        return results

    def getStlCategory(self):
        # return a strings
        return "ECY_Selecting"

    def getStlCurDir(self):
        # return a strings
        return escQuote(lfEncode(os.getcwd()))
        # importance: LeaderF has the same function. and change it to os.cwd
        # and LeaderF will provoke a windows when calling this function,
        # so when you call rooter#GetCurrentBufferWorkSpace(), it return None
        # result = lfEval("rooter#GetCurrentBufferWorkSpace()")


# *****************************************************
# ECYDiagnosisManager
# *****************************************************
class ECYDiagnosisManager(Manager):
    def __init__(self):
        super(ECYDiagnosisManager, self).__init__()
        self._match_ids = []

    def _callback_to_vim(self, event_name, line_content, modes):
        global g_callback_name
        if line_content is not None:
            index = self._get_index(line_content)
        else:
            index = '-1'

        if modes is None or modes == '':
            modes = 'nothing'
        if line_content is not None:
            line_content = line_content.replace("'", "\"")
        cmd = "call leaderf_ECY#items_selecting#LeaderF_cb('{0}','{1}','{2}','{3}','{4}')".\
            format(line_content, event_name, index, modes, g_callback_name)
        lfCmd(cmd)

    def _get_index(self, line):
        """return strings
        """
        i = len(line) - 1
        temp = ""
        while i > 0:
            if line[i] != " ":
                temp = line[i] + temp
            else:
                return temp
            i -= 1
        return '-1'

    def _getExplClass(self):
        return ECYDiagnosisExplorer

    def _defineMaps(self):
        lfCmd("call leaderf_ECY#items_selecting#Maps()")

    def _acceptSelection(self, *args, **kwargs):
        if len(args) == 0:
            return
        line = args[0]
        mode = kwargs.get("mode", '')
        self._callback_to_vim('acceptSelection', str(line), mode)

    def _getDigest(self, line, mode):
        """
        specify what part in the line to be processed and highlighted
        Args:
            mode: 0, 1, 2, return the whole line
        """
        if not line:
            return ''
        i = 0
        for item in line:
            if item == "|":
                return line[:i]
            i += 1

    def _getDigestStartPos(self, line, mode):
        """
        return the start position of the digest returned by _getDigest()
        Args:
            mode: 0, 1, 2, return 1
        """
        return 0

    def _createHelp(self):
        help = []
        help.append('" <CR>/<double-click>/o : execute command under cursor')
        help.append(
            '" x : open file under cursor in a horizontally split window')
        help.append(
            '" v : open file under cursor in a vertically split window')
        help.append('" t : open file under cursor in a new tabpage')
        help.append('" i : switch to input mode')
        help.append('" p : preview the result')
        help.append('" q : quit')
        help.append('" <F1> : toggle this help')
        help.append(
            '" ---------------------------------------------------------')
        return help

    # TODO: highlight for line.
    # def _afterEnter(self):
    #     super(ECYDiagnosisManager, self)._afterEnter()
    #     id = int(lfEval('''matchadd('Lf_hl_marksTitle', '^mark line .*$')'''))
    #     self._match_ids.append(id)
    #     id = int(lfEval('''matchadd('Lf_hl_marksLineCol', '^\s*\S\+\s\+\zs\d\+\s\+\d\+')'''))
    #     self._match_ids.append(id)
    #     id = int(lfEval('''matchadd('Lf_hl_marksText', '^\s*\S\+\s\+\d\+\s\+\d\+\s*\zs.*$')'''))
    #     self._match_ids.append(id)

    def _beforeExit(self):
        super(ECYDiagnosisManager, self)._beforeExit()
        for i in self._match_ids:
            lfCmd("silent! call matchdelete(%d)" % i)
        self._match_ids = []
        self._callback_to_vim('beforeExit', None, 'beforeExit')

    def _previewResult(self, preview):
        if not self._needPreview(preview):
            return
        line = self._getInstance().currentLine
        orig_pos = self._getInstance().getOriginalPos()
        cur_pos = (vim.current.tabpage, vim.current.window, vim.current.buffer)

        saved_eventignore = vim.options['eventignore']
        vim.options['eventignore'] = 'BufLeave,WinEnter,BufEnter'
        try:
            vim.current.tabpage, vim.current.window = orig_pos[:2]
            self._callback_to_vim('previewResult', str(line), 'preview')
        finally:
            vim.current.tabpage, vim.current.window, vim.current.buffer = cur_pos
            vim.options['eventignore'] = saved_eventignore


# *****************************************************
# ECYDiagnosisManager is a singleton
# *****************************************************
ECY_leaderf_selecting = ECYDiagnosisManager()

__all__ = ['ECY_leaderf_selecting']
