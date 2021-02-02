# Author: Jimmy Huang (1902161621@qq.com)
# License: WTFPL

# -*- coding: utf-8 -*-
# standard lib of python
import re
import copy


class FuzzyMatch(object):
    """Return the matchest results of top xx"""

    def __init__(self, result_items_count=0,
                 lower_unsensitive=1,
                 fully_match=True):
        self._result_items_count = result_items_count
        self._lower_unsensitive = lower_unsensitive
        self._fully_match = fully_match
        self._matched_point = []

    def FilterItems(self, sort_text, items,
                    isfully_match=True,
                    isreturn_match_point=False,
                    isindent=False,
                    max_len_2_show=15):
        """items formmat:
        [{'abbr':'xxxxyy','something_else':'will not affect',...},
        ...
        {'abbr':'xxxxyy','something_else':'will not affect'}]
        """
        sort_text_len = len(sort_text)
        vim_items = []
        for item in items:
            if len(item['abbr']) >= sort_text_len:
                goal = self.CalculateGoal(sort_text, item['abbr'])
                if isreturn_match_point:
                    # the self._matched_point will be changed when calling
                    # self.CalculateGoal
                    item['match_point'] = self._matched_point
                i = len(vim_items) - 1
                item_ = {'results': item, 'goal': goal}
                while i >= 0:
                    temp = vim_items[i]
                    if temp['goal'] > goal:
                        if i == 0:
                            vim_items.insert(i, item_)
                            break
                        i -= 1
                    else:
                        if temp['results'] != item:
                            vim_items.insert(i+1, item_)
                        break
                if len(vim_items) == 0:
                    vim_items.append(item_)
                else:
                    # we don't list out all the items, we advocate that user
                    # type more keys to get what he want but not selecting.
                    if len(vim_items) > max_len_2_show:
                        vim_items.pop()

        results_list = []
        for item in vim_items:
            if item['goal'] < 1000 or not isfully_match:
                temp = item['results']
                results_list.append(temp)

        if isindent:
            # format
            name_std_len = 1
            j = 0
            origin_lists = copy.deepcopy(results_list)
            lists = []
            for item in origin_lists:
                if j > max_len_2_show:
                    break
                lists.append(item)
                length = len(item['abbr'])
                if length > name_std_len:
                    name_std_len = length
                j += 1
            # make an interval with space
            name_std_len += 2
            for item in lists:
                space_to_be_added = name_std_len - len(item['abbr'])
                i = 0
                while i < space_to_be_added:
                    item['abbr'] += ' '
                    i += 1
            return lists

        return results_list

    def sub(self, string, position, replace_char):
        new = []
        for s in string:
            new.append(s)
        new[position] = replace_char
        return ''.join(new)

    def CalculateGoal(self, sort_text, text, isHightLight=False,
                      HightLightStyle=3):
        goal = 0
        k = 0
        i = 0
        sort_text_length = len(sort_text)
        item_length = len(text)
        # origin_text_for_hight = bytes(text,encoding='utf-8')
        origin_text_for_hight = text
        match_point = []

        while i < sort_text_length:
            sort_text_temp = sort_text[i]
            j = text.find(sort_text_temp, k, item_length)

            if self._lower_unsensitive and sort_text_temp.islower():
                sort_text_temp = sort_text_temp.upper()
                m = text.find(sort_text_temp, k, item_length)
                if (j > m and m != -1) or j == -1:
                    j = m

            if j != -1:
                k = j + 1
                goal += j
                if isHightLight:
                    # TODO:
                    if origin_text_for_hight[j] in self.replace_map:
                        repalce_word = self.replace_map
                        [origin_text_for_hight[j]][HightLightStyle]
                        origin_text_for_hight = self.sub(
                            origin_text_for_hight, j, repalce_word)
                match_point.append(j)
            else:
                goal += 1000
                if self._fully_match:
                    break
            i += 1
        self._matched_point = match_point
        if isHightLight:
            return origin_text_for_hight
        else:
            return goal
