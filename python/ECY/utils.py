import re


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
