import json
import os

BASE_DIR = os.path.abspath(os.path.dirname(__file__))

with open(BASE_DIR + '/default_config.json', encoding='utf-8') as f:
    content = f.read()

content = json.loads(content)

res = ''
for item1 in content:
    res += "%s:\n" % item1
    for item2 in content[item1]:
        if 'default_value' in content[item1][item2]:
            default_value = content[item1][item2]['default_value']
        else:
            default_value = 'null'
        res += "\tname: '%s'\t default_value: '%s'\n" % (item2, default_value)
    res += '\n\n'
print(res)
