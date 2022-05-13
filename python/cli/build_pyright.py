import json

with open('./node_modules/pyright/package.json', 'r') as f:
    content = f.read()
    content = json.loads(content)
    f.close()

content['bin']['pyright'] = 'langserver.index.js'
content['pkg'] = {"assets": ["dist/*"]}

with open('./node_modules/pyright/package.json', 'w') as f:
    f.write(json.dumps(content))
    f.close()
