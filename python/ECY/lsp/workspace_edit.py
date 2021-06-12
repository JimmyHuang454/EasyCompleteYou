import copy
import os
import shutil


def Delete(context, is_check=False):
    path = context['uri']
    ignoreIfNotExists = False
    recursive = True
    if 'options' in context:
        if 'ignoreIfNotExists' in context['options']:
            ignoreIfNotExists = context['options']['ignoreIfNotExists']
        elif 'recursive' in context['options']:
            recursive = context['options']['recursive']

    if os.path.exists(path):
        if ignoreIfNotExists:
            return
        raise ValueError('the file try to delete is not exists')

    is_dir = os.path.isdir(path)

    if is_dir and not recursive:
        raise ValueError(
            'cannot delelte a dir, please set options.recursive = true')

    if is_check:
        try:
            with open(path, 'rw') as f:
                f.close()
        except Exception as e:
            raise e
        return

    if is_dir:
        shutil.rmtree(path)
    else:
        os.remove(path)


def Rename(context, is_check=False):
    old_path = context['oldUri']
    new_path = context['newUri']
    ignoreIfNotExists = False
    overwrite = False
    if 'options' in context:
        if 'ignoreIfNotExists' in context['options']:
            ignoreIfNotExists = context['options']['ignoreIfNotExists']
        elif 'overwrite' in context['options']:
            overwrite = context['options']['overwrite']

    if not os.path.exists(old_path):
        if ignoreIfNotExists:
            return
        raise ValueError('the file try to operate is not exists')

    if os.path.exists(new_path):
        if not overwrite:
            raise ValueError('new name tring to rename is already exists.')

    if is_check:
        return

    os.rename(old_path, new_path)


def Create(context, is_check=False):
    pass


def TextEdit2(text_edit_list, file_context):
    added_line = file_context['added_line']
    original_text = file_context['original_text']
    for text_edit in text_edit_list:
        original_text_len = len(original_text)
        start_line = text_edit['range']['start']['line']
        start_colum = text_edit['range']['start']['character']
        end_line = text_edit['range']['end']['line']
        end_colum = text_edit['range']['end']['character']
        start_line += added_line
        end_line += added_line
        if start_line >= original_text_len or end_line >= original_text_len:
            raise ValueError('out of range')
        old_line = len(original_text)
        replace_text = original_text[start_line][:start_colum] + text_edit[
            'newText'] + original_text[end_line][end_colum:]
        replace_text = replace_text.split('\n')
        effect_line_wide = (end_line - start_line) + 1
        if effect_line_wide == 1:
            original_text.pop(start_line)
        else:
            for item in range(effect_line_wide):
                original_text.pop(start_line)
        i = start_line
        for item in replace_text:
            original_text.insert(i, item)
            i += 1
        added_line += len(original_text) - old_line
    return {'added_line': added_line, 'original_text': original_text}


def ReadFileContent(file_uri):
    # open a file; if it's not exists or have no right to operate them raise a error
    with open(file_uri, 'r+', encoding='utf-8') as f:
        content = f.read()
        f.close()
    split_content = content.split('\n')
    return split_content


def Check(workspace_edit):
    file_will_be_operate = []
    if 'documentChanges' in workspace_edit:
        for item in text_edit['documentChanges']:
            if 'kind' in item:  # file operation
                try:
                    temp = {'kind': item['kind'], 'uri': []}
                    if item['kind'] == 'create':  # new a file
                        temp['uri'] = [item['newUri'], item['oldUri']]
                        Create(item, is_check=True)
                    elif item['kind'] == 'rename':
                        temp['uri'] = [item['uri']]
                        Rename(item, is_check=True)
                    elif item['kind'] == 'delete':
                        temp['uri'] = [item['uri']]
                        Delete(item, is_check=True)
                    file_will_be_operate.append(temp)
                except Exception as e:
                    return e
            else:  # TextDocumentEdit
                file_will_be_operate.append({
                    'kind': 'change',
                    'uri': [item['uri']]
                })
    if 'changes' in workspace_edit:
        for file_uri in workspace_edit['changes']:
            file_will_be_operate.append({'kind': 'change', 'uri': [file_uri]})
    return file_will_be_operate


def Apply(workspace_edit):
    file_change_list = []
    if 'documentChanges' in workspace_edit:
        for item in text_edit['documentChanges']:
            if 'kind' in item:  # file operation
                if item['kind'] == 'create':  # new a file
                    Create(item)
                elif item['kind'] == 'rename':
                    Rename(item)
                elif item['kind'] == 'delete':
                    Delete(item)
            else:  # TextDocumentEdit
                file_change_list.append({
                    'uri': item['uri'],
                    'edit_list': item['edits']
                })

    if 'changes' in workspace_edit:
        for file_uri in workspace_edit['changes']:
            file_change_list.append({
                'uri':
                file_uri,
                'edit_list':
                workspace_edit['changes'][file_uri]
            })

    file_edit_info = {}
    for item in file_change_list:
        file_uri = item['uri']
        if file_uri not in file_edit_info:
            file_edit_info[file_uri] = {
                'added_line': 0,
                'original_text': ReadFileContent(file_uri)
            }
        TextEdit2(
            item['edit_list'],
            file_edit_info[file_uri])  # make sure file_edit_info has changed
    return file_edit_info


test_uir = "C:/Users/qwer/Desktop/vimrc/myproject/ECY/RPC/EasyCompleteYou2/python/ECY/lsp/test.txt"

workspace_edit_test = {
    "changes": {
        test_uir: [{
            "newText": "test1\n",
            "range": {
                "end": {
                    "character": 0,
                    "line": 0
                },
                "start": {
                    "character": 0,
                    "line": 0
                }
            }
        }, {
            "newText": "test2\n",
            "range": {
                "end": {
                    "character": 0,
                    "line": 1
                },
                "start": {
                    "character": 0,
                    "line": 1
                }
            }
        }]
    }
}
print(Check(workspace_edit_test))
res = Apply(workspace_edit_test)
res = res[test_uir]['original_text']
assert res == ['test1', 'line 0', 'test2', 'line 1', 'line 2', '']

#############
#  test2  #
#############
workspace_edit_test = {
    "changes": {
        test_uir: [{
            "newText": "test",
            "range": {
                "end": {
                    "character": 0,
                    "line": 0
                },
                "start": {
                    "character": 0,
                    "line": 0
                }
            }
        }]
    }
}

res = Apply(workspace_edit_test)
res = res[test_uir]['original_text']
assert res == ['testline 0', 'line 1', 'line 2', '']

#############
#  test3  #
#############
workspace_edit_test = {
    "changes": {
        test_uir: [{
            "newText": "test",
            "range": {
                "end": {
                    "character": 6,
                    "line": 2
                },
                "start": {
                    "character": 0,
                    "line": 0
                }
            }
        }]
    }
}

res = Apply(workspace_edit_test)
res = res[test_uir]['original_text']
assert res == ['test', '']
