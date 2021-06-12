import copy
import os
import shutil


def Delete(context):
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

    if is_dir:
        shutil.rmtree(path)
    else:
        os.remove(path)


def Rename(context):
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

    os.rename(old_path, new_path)


def Create(context):
    pass


def Apply(workspace_edit, original_text):
    inserted_line_count = 0
    if 'changes' in workspace_edit:
        for file_item in workspace_edit['changes']:
            for text_edit in workspace_edit['changes'][file_item]:
                original_text_len = len(original_text)
                start_line = text_edit['range']['start']['line']
                start_colum = text_edit['range']['start']['character']
                end_line = text_edit['range']['end']['line']
                end_colum = text_edit['range']['end']['character']
                start_line += inserted_line_count
                end_line += inserted_line_count
                if start_line >= original_text_len or end_line >= original_text_len:
                    raise ValueError('out of range')
                old_line = len(original_text)
                replace_text = original_text[
                    start_line][:start_colum] + text_edit[
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
                inserted_line_count += len(original_text) - old_line
    if 'documentChanges' in text_edit:
        for item in text_edit['documentChanges']:
            if 'kind' in item:  # file operation
                if item['kind'] == 'create':  # new a file
                    Create(item)
                elif item['kind'] == 'rename':
                    Rename(item)
                elif item['kind'] == 'delete':
                    Delete(item)
            else:  # TextDocumentEdit
                pass
    return original_text


original_text = ['line 0', 'line 1', 'line 2']

workspace_edit_test = {
    "changes": {
        "file:///C:/Users/qwer/Desktop/vimrc/myproject/test.cpp": [{
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
res = Apply(workspace_edit_test, copy.copy(original_text))
assert res == ['test1', 'line 0', 'test2', 'line 1', 'line 2']

#############
#  test2  #
#############
workspace_edit_test = {
    "changes": {
        "file:///C:/Users/qwer/Desktop/vimrc/myproject/test.cpp": [{
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

res = Apply(workspace_edit_test, copy.copy(original_text))
assert res == ['testline 0', 'line 1', 'line 2']

#############
#  test3  #
#############
workspace_edit_test = {
    "changes": {
        "file:///C:/Users/qwer/Desktop/vimrc/myproject/test.cpp": [{
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

res = Apply(workspace_edit_test, copy.copy(original_text))
assert res == ['test']
