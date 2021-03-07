import re
from ECY import rpc


def MatchFilterKeys(line_text, regex):
    """Find matched key in line_text. Start matching at the tail
    such as line_text = "abcd ab", regex = r'[\w+]', return "ab"
    """
    start_position = len(line_text)
    text_len = start_position - 1
    last_key = ''
    match_words = ''
    if text_len < 300:
        while text_len >= 0:
            temp = line_text[text_len]
            if (re.match(regex, temp) is not None):
                match_words = temp + match_words
                start_position -= 1
                if text_len == 0:
                    break
                text_len = text_len - 1
                continue
            break
        if start_position != 0:
            last_key = line_text[start_position - 1]
        elif text_len >= 0:
            last_key = line_text[0]
    return start_position, match_words, last_key


def IsNeedToUpdate(context, regex):
    params = context['params']
    current_colum = params['buffer_position']['colum']
    current_line = params['buffer_position']['line']
    current_line_content = params['buffer_position']['line_content']
    temp = bytes(current_line_content, encoding='utf-8')
    prev_string = str(temp[:current_colum], encoding='utf-8')

    current_colum, filter_words, last_key = MatchFilterKeys(prev_string, regex)
    cache = {
        'current_line': current_line,
        'current_colum': current_colum,
        'last_key': last_key,
        'prev_string': prev_string
    }

    if prev_string == '':
        cache['prev_string_last_key'] = ' '
    else:
        cache['prev_string_last_key'] = prev_string[len(prev_string) - 1]

    if 'buffer_content' in params:
        cache['line_counts'] = len(params['buffer_content'])
    return cache


def GetDefaultValue(var_name, default_value):
    if rpc.DoCall('exists', [var_name]):
        default_value = rpc.GetVaribal(var_name)
    return default_value
