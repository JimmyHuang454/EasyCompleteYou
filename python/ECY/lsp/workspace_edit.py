import copy
import os
import shutil
from ECY.lsp import language_server_protocol
from ECY import rpc

my_lsp = language_server_protocol.LSP(timeout=1)


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
    path = context['uri']
    ignoreIfNotExists = False
    overwrite = False
    if 'options' in context:
        if 'ignoreIfNotExists' in context['options']:
            ignoreIfNotExists = context['options']['ignoreIfNotExists']
        elif 'overwrite' in context['options']:
            overwrite = context['options']['overwrite']

    if os.path.exists(path):
        if overwrite is False:
            if not ignoreIfNotExists:
                raise ValueError('the file try to create is exists')

    if is_check:
        return

    with open(path, 'w+') as f:  # overwrite if it is exist, new if it is not.
        f.close()


def TextEdit(text_edit_list, file_context):
    added_line = file_context['added_line']
    replace_line_list = []
    text = file_context['text']
    for text_edit in text_edit_list:
        original_text_len = len(text)
        start_line = text_edit['range']['start']['line']
        start_colum = text_edit['range']['start']['character']
        end_line = text_edit['range']['end']['line']
        end_colum = text_edit['range']['end']['character']

        if start_line in file_context['added_colum']:
            added_colum = file_context['added_colum'][start_line]
            start_colum += added_colum
            if start_line == end_line:
                end_colum += added_colum
        start_line += added_line
        end_line += added_line

        if start_line >= original_text_len or end_line >= original_text_len:
            raise ValueError('out of range')
        old_line_len = len(text)
        old_colum_len = len(text[end_line])
        replace_text = text[start_line][:start_colum] + text_edit[
            'newText'] + text[end_line][end_colum:]
        replace_text = replace_text.split('\n')
        effect_line_wide = (end_line - start_line) + 1
        if effect_line_wide == 1:
            text.pop(start_line)
        else:
            for item in range(effect_line_wide):
                text.pop(start_line)
        i = start_line
        for item in replace_text:
            text.insert(i, item)
            i += 1

        this_added_line = len(text) - old_line_len
        temp = []
        for item in range(effect_line_wide + this_added_line):
            i = start_line + item
            temp.append(text[i])
        temp = {
            'start_line': start_line,
            'end_line': end_line,
            'replace_list': temp
        }
        replace_line_list.append(temp)
        added_line += this_added_line

        # update colum
        end_line = text_edit['range']['end']['line']
        new_colum_len = len(text[end_line + added_line])
        added_colum = new_colum_len - old_colum_len
        if added_colum != 0:
            if end_line not in file_context['added_colum']:
                file_context['added_colum'][end_line] = 0
            file_context['added_colum'][end_line] += added_colum

    file_context = {
        'added_line': added_line,
        'text': text,
        'undo_text': file_context['undo_text'],
        'replace_line_list': replace_line_list,
        'added_colum': file_context['added_colum']
    }
    return file_context


def ReadFileContent(path):
    # open a file; if it's not exists or have no right to operate them raise a error
    res = rpc.DoCall('ECY#utils#IsFileOpenedInVim', [path, 'return_list'])
    if res is False:
        with open(path, 'r+', encoding='utf-8') as f:
            content = f.read()
            f.close()
        res = content.split('\n')
    return res


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
    elif 'changes' in workspace_edit:
        for file_uri in workspace_edit['changes']:
            file_will_be_operate.append({'kind': 'change', 'uri': [file_uri]})
    return file_will_be_operate


def Apply(workspace_edit):
    file_change_list = []
    if 'documentChanges' in workspace_edit:
        for item in workspace_edit['documentChanges']:
            if 'kind' in item:  # file operation
                if item['kind'] == 'create':  # new a file
                    Create(item)
                elif item['kind'] == 'rename':
                    Rename(item)
                elif item['kind'] == 'delete':
                    Delete(item)
            else:  # TextDocumentEdit
                file_change_list.append(item)
    elif 'changes' in workspace_edit:
        for file_uri in workspace_edit['changes']:
            file_change_list.append({
                'textDocument': {
                    'uri': file_uri,
                    'version': None
                },
                'edits':
                workspace_edit['changes'][file_uri]
            })

    file_edit_info = {}
    for item in file_change_list:
        file_uri = item['textDocument']['uri']
        file_uri = my_lsp.UriToPath(file_uri)
        item['textDocument']['uri'] = file_uri
        if file_uri not in file_edit_info:
            text_list = ReadFileContent(file_uri)
            file_edit_info[file_uri] = {
                'added_line': 0,
                'textDocument': item['textDocument'],
                'text': text_list,
                'undo_text': copy.copy(text_list),
                'added_colum': {}
            }
        # make sure file_edit_info has changed
        file_edit_info[file_uri] = TextEdit(item['edits'],
                                            file_edit_info[file_uri])
    return file_edit_info


def WorkspaceEdit(workspace_edit):
    return Apply(workspace_edit)
