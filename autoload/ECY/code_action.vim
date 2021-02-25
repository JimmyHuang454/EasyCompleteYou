" {"id":9,"jsonrpc":"2.0","result":[{"diagnostics":[{"code":"expected_semi_after_expr","message":"Expected ';' after expression (fix available)","range":{"end":{"character":4,"line":9},"start":{"character":2,"line":9}},"severity":1,"source":"clang"}],"edit":{"changes":{"file:///C:/Users/qwer/Desktop/vimrc/myproject/test.cpp":[{"newText":";","range":{"end":{"character":8,"line":8},"start":{"character":8,"line":8}}}]}},"kind":"quickfix","title":"insert ';'"}]}

" {"id":24,"jsonrpc":"2.0","result":[{"command":{"arguments":[{"file":"file:///C:/Users/qwer/Desktop/vimrc/myproject/test.cpp","selection":{"end":{"character":51,"line":14},"start":{"character":9,"line":14}},"tweakID":"ExtractVariable"}],"command":"clangd.applyTweak","title":"Extract subexpression to variable"},"kind":"refactor","title":"Extract subexpression to variable"}]}

fun! ECY#code_action#Do(context)
"{{{
  let l:current_buffer_path = ECY#utils#GetCurrentBufferPath()
  if l:current_buffer_path != a:context['params']['buffer_path'] 
        \|| ECY#rpc#rpc_event#GetBufferIDNotChange() != a:context['params']['buffer_id']
    return
  endif

  let l:results = a:context['result']['result']
  let l:edit_res = {}
  if len(l:results) == 0
    call ECY#utils#echo('Nothing to act.')
    return
  endif

  for item in l:results
    if has_key(item, 'edit')
      let l:edit_res = s:ApplyEdit(item['edit'])

    endif

    if has_key(item, 'command')
      if type(item['command']) == v:t_string
        " it is a command response.
        let l:temp = item
      else
        " code_action with command
        let l:temp = item['command']
      endif
      let l:cmd_name = l:temp['command']
      let l:cmd_args = get(l:temp, 'arguments', [])
      call ECY2_main#DoCmd(l:cmd_name, l:cmd_args)
    endif
  endfor

  call s:Switch(l:current_buffer_path)
  redraw!
  echo l:edit_res

  "}}}
endf

fun! s:HandleEdit(edit_dict)
"{{{
  let l:to_be_done_action = []
  let l:not_to_do_action = []
  for item in a:edit_dict
    " if has_key(item, 'range')
    "   let current_position = ECY#utils#GetCurrentBufferPosition()
    "   if current_position['line'] > item['range']['end']['line'] || 
    "         \current_position['line'] < item['range']['start']['line'] ||
    "         \current_position['colum'] > item['range']['end']['character'] || 
    "         \current_position['colum'] < item['range']['start']['character']

    "     call add(l:not_to_do_action, item)
    "     continue
    "   endif
    " endif

    if !has_key(item, 'edit')
      call add(l:not_to_do_action, item)
      continue
    endif

    try
      " do this action
      call s:ApplyEdit(item['edit'])
      call add(l:to_be_done_action, item)
    catch 
      call add(l:not_to_do_action, item)
    endtry

  endfor
  echo l:to_be_done_action
  echo l:not_to_do_action
"}}}
endf

function! s:Switch(path) abort
"{{{
  if bufnr(a:path) >= 0
    execute printf('keepalt keepjumps %sbuffer!', bufnr(a:path))
  else
    execute printf('keepalt keepjumps edit! %s', fnameescape(a:path))
  endif
"}}}
endfunction

fun! s:ApplyEdit(workspace_edit)
"{{{
  let l:changed = []
  if has_key(a:workspace_edit, 'changes')
    for item in keys(a:workspace_edit['changes'])
      let l:path = UriToPath(item)
      call s:Switch(l:path)
      for item2 in a:workspace_edit['changes'][item]
        call s:Apply(l:path, item2, ECY#utils#GetCurrentBufferPosition())
        call add(l:changed, l:path)
      endfor
    endfor
  endif

  return {'changed': l:changed}
"}}}
endf

" copy from vim-lsp (MIT LICENSE)
"{{{
function! s:Apply(bufnr, text_edit, cursor_position) abort
"{{{
    " create before/after line.
    let l:start_line = getline(a:text_edit['range']['start']['line'] + 1)
    let l:end_line = getline(a:text_edit['range']['end']['line'] + 1)
    let l:before_line = strcharpart(l:start_line, 0, a:text_edit['range']['start']['character'])
    let l:after_line = strcharpart(l:end_line, a:text_edit['range']['end']['character'], strchars(l:end_line) - a:text_edit['range']['end']['character'])

    " create new lines.
    let l:new_lines = s:Split(a:text_edit['newText'])
    let l:new_lines[0] = l:before_line . l:new_lines[0]
    let l:new_lines[-1] = l:new_lines[-1] . l:after_line

  " save length.
    let l:new_lines_len = len(l:new_lines)
    let l:range_len = (a:text_edit['range']['end']['line'] - a:text_edit['range']['start']['line']) + 1

    " fixendofline
    let l:buffer_length = len(getbufline(a:bufnr, '^', '$'))
    let l:should_fixendofline = s:get_fixendofline(a:bufnr)
    let l:should_fixendofline = l:should_fixendofline && l:new_lines[-1] ==# ''
    let l:should_fixendofline = l:should_fixendofline && l:buffer_length <= a:text_edit['range']['end']['line']
    let l:should_fixendofline = l:should_fixendofline && a:text_edit['range']['end']['character'] == 0
    if l:should_fixendofline
        call remove(l:new_lines, -1)
    endif

    " fix cursor pos
    if a:text_edit['range']['end']['line'] < a:cursor_position['line']
        " fix cursor line
        let a:cursor_position['line'] += l:new_lines_len - l:range_len
    elseif a:text_edit['range']['end']['line'] == a:cursor_position['line'] && a:text_edit['range']['end']['character'] <= a:cursor_position['colum']
        " fix cursor line and col
        let a:cursor_position['line'] += l:new_lines_len - l:range_len
        let l:end_character = strchars(l:new_lines[-1]) - strchars(l:after_line)
        let l:end_offset = a:cursor_position['colum'] - a:text_edit['range']['end']['character']
        let a:cursor_position['colum'] = l:end_character + l:end_offset
    endif

    " append or delete lines.
    if l:new_lines_len > l:range_len
        call append(a:text_edit['range']['start']['line'], repeat([''], l:new_lines_len - l:range_len))
    elseif l:new_lines_len < l:range_len
        let l:offset = l:range_len - l:new_lines_len
        call s:delete(a:bufnr, a:text_edit['range']['start']['line'] + 1, a:text_edit['range']['start']['line'] + l:offset)
    endif

    " set lines.
    call setline(a:text_edit['range']['start']['line'] + 1, l:new_lines)
"}}}
endfunction

function! s:Split(text) abort
"{{{
    return split(a:text, '\r\n\|\r\|\n', v:true)
"}}}
endfunction

let s:fixendofline_exists = exists('+fixendofline')

function! s:get_fixendofline(buf) abort
"{{{
    let l:eol = getbufvar(a:buf, '&endofline')
    let l:binary = getbufvar(a:buf, '&binary')

    if s:fixendofline_exists
        let l:fixeol = getbufvar(a:buf, '&fixendofline')

        if !l:binary
            " When 'binary' is off and 'fixeol' is on, 'endofline' is not used
            "
            " When 'binary' is off and 'fixeol' is off, 'endofline' is used to
            " remember the presence of a <EOL>
            return l:fixeol || l:eol
        else
            " When 'binary' is on, the value of 'fixeol' doesn't matter
            return l:eol
        endif
    else
        " When 'binary' is off the value of 'endofline' is not used
        "
        " When 'binary' is on 'endofline' is used to remember the presence of
        " a <EOL>
        return !l:binary || l:eol
    endif
"}}}
endfunction
"}}}

" call ECY#code_action#Do({'result': {"id":9,"jsonrpc":"2.0","result":[{"diagnostics":[{"code":"expected_semi_after_expr","message":"Expected ';' after expression (fix available)","range":{"end":{"character":4,"line":9},"start":{"character":2,"line":9}},"severity":1,"source":"clang"}],"edit":{"changes":{"file:///C:/Users/qwer/Desktop/vimrc/myproject/test.cpp":[{"newText":";","range":{"end":{"character":8,"line":8},"start":{"character":8,"line":8}}}]}},"kind":"quickfix","title":"insert ';'"}]}})
