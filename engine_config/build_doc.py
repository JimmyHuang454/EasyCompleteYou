import json

with open('./default_config.json', 'r') as f:
    content = f.read()
    content = json.loads(content)

with open('./engines.json', 'r') as f:
    engine_list = f.read()
    engine_list = json.loads(engine_list)

def IsDisabled(engine_name):
    for item in engine_list['engines_list']:
        if item['engine_name'] == engine_name:
            if 'disabled' in item and item['disabled']:
                return True
            return False
    return False

res = []
for item in content:
    if IsDisabled(item):
        continue
    temp = "|%s| Type  | Default Value | Des |\n" % item
    temp += "| - | :-: | -: | - |\n"
    for item2 in content[item]:
        name = str(item) + '.' + str(item2)
        des = "".join(content[item][item2]['des'])
        default_value = str(content[item][item2]['default_value'])
        default_value = default_value.replace('<', '\\<')
        default_value = default_value.replace('>', '\\>')
        if des == '':
            des = '-'
        if default_value == '':
            default_value = '-'
        temp += "|%s|%s|%s|%s|\n" % (item2, content[item][item2]['type'],
                                     default_value, des)
    print(temp)
    print('\n')
