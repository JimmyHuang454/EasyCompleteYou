import json

with open('./default_config.json', 'r') as f:
    content = f.read()
    content = json.loads(content)

res = []
for item in content:
    temp = "|%s| Type  | Default Value | Des |\n" % item
    temp += "| - | :-: | -: | - |\n"
    for item2 in content[item]:
        name = str(item) + '.' + str(item2)
        des = "".join(content[item][item2]['des'])
        if des == '':
            des = '-'
        temp += "|%s|%s|%s|%s|\n" % (item2, content[item][item2]['type'],
                                     content[item][item2]['default_value'],
                                     des)
    print(temp)
    print('\n')
