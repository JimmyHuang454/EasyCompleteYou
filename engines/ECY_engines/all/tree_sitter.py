import os
import sys
import copy

from tree_sitter import Language, Parser
from ECY import utils
from ECY.debug import logger

BASE_DIR = 'C:/Users/qwer/Desktop/vimrc/myproject/ECY/RPC/tree_sitter'
LIB_BIN = BASE_DIR + '/bin/main.so'

VENDOR_LIST = [BASE_DIR + '/vendor/tree-sitter-python']
Language.build_library(LIB_BIN, VENDOR_LIST)


class TreeSitter(object):
    def __init__(self, language_type, encoding='utf-8'):
        self.language_type = language_type
        self.encoding = encoding
        self.parser = Parser()
        self.parser.set_language(Language(LIB_BIN, self.language_type))
        self.UpdateBuffer([""])
        self._res = []

    def DFS(self, node, tokenModifiers: list):
        for item in node.children:
            temp = tokenModifiers
            if len(item.children) != 0:
                temp = copy.copy(tokenModifiers)
                temp.append(item.type)
                self.DFS(item, temp)
            self._res.append({
                'node': item.type,
                'tokenModifiers': tokenModifiers
            })

    def GetSematicToken(self):
        self._res = []
        self.DFS(self.tree.root_node, [])
        return self._res

    def UpdateBuffer(self, content_list):
        self.tree = self.parser.parse(
            bytes("\n".join(content_list), self.encoding))


AVAILABLE_PARSER = ['python']


class Operate(object):
    def __init__(self, engine_name):
        self.engine_name = engine_name
        self.parser = {}
        for item in AVAILABLE_PARSER:
            self.parser[item] = TreeSitter(item)
        self.highlight = utils.GetEngineConfig(self.engine_name, 'highlight')

    def OnTextChanged(self, context):
        params = context['params']
        filetype = params['file_type']
        if filetype not in self.parser or filetype not in self.highlight:
            return
        text = params['buffer_content']
        obj = self.parser[filetype]
        obj.UpdateBuffer(text)
        res = obj.GetSematicToken()
        to_vim = []
        color_info = self.highlight[filetype]

        if 'color' in color_info:
            for item in res:
                is_defined = True
                for color_item in self.highlight[filetype]['color']:
                    for color in color_item[0]:
                        if color not in item[
                                'tokenModifiers'] and color != item['type']:
                            is_defined = False
                            break
                    if is_defined:
                        item['color'] = color_item[1]
                        to_vim.append(item)
                        break
            logger.debug(to_vim)
        if params['change_mode'] == 'n':  # normal mode
            pass
