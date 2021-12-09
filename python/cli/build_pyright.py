with open('./node_modules/pyright/package.json', 'r') as f:
    content = f.read()
    content = content.replace('"index.js"', '"langserver.index.js"')
    f.close()

with open('./node_modules/pyright/package.json', 'w') as f:
    f.write(content)
    f.close()
