" for echo
let s:show_msg_windows_nr = -1
let s:show_msg_windows_text_list = []
let s:show_msg_time = 5
let s:show_msg_timer_id = -1

function! g:ShowMsg_cb(id, key) abort
"{{{
  let s:show_msg_windows_nr = -1
"}}}
endfunction

function! g:ShowMsg_timer(timer_id)
"{{{
  if a:timer_id != s:show_msg_timer_id
    return
  endif
  if s:show_msg_time != 0 
    let s:show_msg_time -= 1
  else
    if s:show_msg_windows_nr != -1
      call popup_close(s:show_msg_windows_nr)
    endif
    return
  endif
 let l:temp = 'Message Box Closing in ' . string(s:show_msg_time) . 's '
 call popup_setoptions(s:show_msg_windows_nr, {'title': l:temp})
 let s:show_msg_timer_id = timer_start(1000, function('g:ShowMsg_timer'))
"}}}
endfunction

fun! ECY#utils#echo(msg)
"{{{
  if g:has_floating_windows_support == 'vim'
"{{{
    let s:show_msg_time = 10
    let l:temp = 'Message Box Closing in ' . string(s:show_msg_time) . 's '
    let l:opts = {
          \ 'callback': 'g:ShowMsg_cb',
          \ 'minwidth': g:ECY_preview_windows_size[0][0],
          \ 'maxwidth': g:ECY_preview_windows_size[0][1],
          \ 'minheight': g:ECY_preview_windows_size[1][0],
          \ 'maxheight': g:ECY_preview_windows_size[1][1],
          \ 'title': l:temp,
          \ 'moved': 'WORD',
          \ 'border': [],
          \ 'borderchars': ['-', '|', '-', '|', '┌', '┐', '┘', '└']
          \}
    if s:show_msg_windows_nr == -1
      let s:show_msg_windows_text_list = []
    else
      call add(s:show_msg_windows_text_list, '--------------------')
    endif
    if type(a:msg) == 3
      " == list
      call extend(s:show_msg_windows_text_list, a:msg)
    else
      call add(s:show_msg_windows_text_list, a:msg)
    endif
    if s:show_msg_windows_nr == -1
      let s:show_msg_windows_nr = popup_create(s:show_msg_windows_text_list, l:opts)
    else
      " delay, have new msg.
      call popup_settext(s:show_msg_windows_nr, s:show_msg_windows_text_list)
    endif
    let s:show_msg_timer_id = timer_start(1000, function('g:ShowMsg_timer'))
"}}}
  elseif g:has_floating_windows_support == 'has_no' 
    if type(a:msg) == 3
      let l:temp = join(a:msg, '|')
    else
      let l:temp = a:msg
    endif
    echohl WarningMsg |
          \ echomsg l:temp |
          \ echohl None
  endif
"}}}
endf

fun! ECY#utils#GetCurrentBufferFileType()
"{{{
  if &filetype == ''
    return 'nothing'
  endif
  return &filetype
"}}}
endf

fun! ECY#utils#Input(hint)
"{{{
  let l:new_name = input(a:hint)
  if l:new_name == ''
    call ECY#utils#echo('Quited input.')
  endif
  return l:new_name
"}}}
endf

fun! ECY#utils#show(msg, style, title)
"{{{
  if type(a:msg) != v:t_string
    let l:msg = join(a:msg, "\n")
  else
    let l:msg = a:msg
  endif
  if a:style == 'buffer'
    exe 'new ' . a:title
    " let l:current_buffer_nr = bufnr()
    call setline(1, l:msg)
  endif
"}}}
endf

function! ECY#utils#GetCurrentBufferPath(...) abort
"{{{
  " let l:full_path = fnamemodify(@%, ':p')
  let l:full_path = expand('%:p')
  return l:full_path
"}}}
endfunction

function ECY#utils#GetCurrentBufferPosition() abort
"{{{ utf-8]
  return { 'line': line('.') - 1, 'colum': col('.') - 1}
"}}}
endfunction

function ECY#utils#GetCurrentLineAndPosition() abort
"{{{
  let l:temp = ECY#utils#GetCurrentBufferPosition()
  let l:temp['line_content'] = getline(".")
  return l:temp
"}}}
endfunction

function ECY#utils#GetCurrentLine() abort
"{{{
  return getline(".")
"}}}
endfunction

function ECY#utils#GetCurrentBufferContent() abort " return list
"{{{
  return ECY#utils#GetBufferContent(bufnr())
"}}}
endfunction

function ECY#utils#GetBufferContent(buffer_nr) abort " return list
"{{{
  return getbufline(a:buffer_nr, 1, "$")
"}}}
endfunction

function ECY#utils#DefineColor(name, colora) abort
"{{{
  if hlexists(a:name) 
    return
  endif
  exe 'hi '.a:name . ' '. a:colora
  if g:has_floating_windows_support == 'vim'
    call prop_type_add(a:name, {'highlight': a:name})
  endif
"}}}
endfunction

function! IsInList(item, list) abort
"{{{
  let i = 0
  while i < len(a:list)
    if a:item == a:list[i]
      return v:true
    endif
    let i += 1
  endw
  return v:false
"}}}
endfunction

function! ECY#utils#MoveToBuffer(line, colum, file_path, windows_to_show) abort
"{{{ move cursor to windows, in normal mode
" a:colum is 0-based
" a:line is 1-based
" the a:windows_to_show hightly fit leaderf

  "TODO
  " if a:windows_to_show == 'preview' && g:ECY_leaderf_preview_mode != 'normal'
  "   if g:has_floating_windows_support == 'vim'
  "     call s:ShowPreview_vim(a:file_path, a:line, &syntax)
  "   endif
  "   return
  " endif

  if a:windows_to_show == 'h' " horizontally new a windows at current tag
    exe 'new ' . a:file_path
  elseif a:windows_to_show == 'v' " vertically new a windows at current tag
    exe 'vnew ' . a:file_path
  elseif a:windows_to_show == 't' " new a windows and new a tab
    exe 'tabedit '
    silent exe "hide edit " .  a:file_path
  elseif a:windows_to_show == 'to' " new a windows and a tab that can be a previous old one.
    silent exe 'tabedit ' . a:file_path
  else
    " use current buffer's windows to open that buffer if current buffer is
    " not that buffer, and if current buffer is that buffer, it will fit
    " perfectly.
    if ECY#utils#GetCurrentBufferPath() != a:file_path
      silent exe "hide edit " .  a:file_path
    endif
  endif
  call cursor(a:line, a:colum + 1)
"}}}
endfunction

function! PathToUri(path) abort
    return s:encode_uri(a:path, 0, 'file://')
endfunction

function! s:encode_uri(path, start_pos_encode, default_prefix) abort
"{{{
    let l:prefix = s:get_prefix(a:path)
    let l:path = a:path[len(l:prefix):]
    if len(l:prefix) == 0
        let l:prefix = a:default_prefix
    endif

    let l:result = strpart(a:path, 0, a:start_pos_encode)

    for l:i in range(a:start_pos_encode, len(l:path) - 1)
        " Don't encode '/' here, `path` is expected to be a valid path.
        if l:path[l:i] =~# '^[a-zA-Z0-9_.~/-]$'
            let l:result .= l:path[l:i]
        else
            let l:result .= s:urlencode_char(l:path[l:i])
        endif
    endfor

    return l:prefix . l:result
"}}}
endfunction

function! s:decode_uri(uri) abort
    let l:ret = substitute(a:uri, '[?#].*', '', '')
    return substitute(l:ret, '%\(\x\x\)', '\=printf("%c", str2nr(submatch(1), 16))', 'g')
endfunction

if has('win32') || has('win64')
    function! UriToPath(uri) abort
        return substitute(s:decode_uri(a:uri[len('file:///'):]), '/', '\\', 'g')
    endfunction
else
    function! UriToPath(uri) abort
        return s:decode_uri(a:uri[len('file://'):])
    endfunction
endif

function! ECY#utils#SendKeys(keys) abort
"{{{
  call feedkeys( a:keys, 'in' )
"}}}
endfunction

function! ECY#utils#GetValue(dicts, key, default_value) abort 
"{{{
  if !has_key(a:dicts, a:key)
    return a:default_value
  endif
  return a:dicts[a:key]
"}}}
endfunction

function! ECY#utils#GetSelectRange() abort 
"{{{
  let l:start_pos = getpos("'<")[1 : 2]
  let l:end_pos = getpos("'>")[1 : 2]
  let l:end_pos[1] += 1 " To exclusive

  " Fix line selection.
  let l:end_line = getline(l:end_pos[0])
  if l:end_pos[1] > strlen(l:end_line)
      let l:end_pos[1] = strlen(l:end_line) + 1
  endif

  let l:range = {}
  let l:range['start'] = ECY#utils#VimPostionToLSPPosition('%', l:start_pos)
  let l:range['end'] = ECY#utils#VimPostionToLSPPosition('%', l:end_pos)
  return l:range
"}}}
endfunction

function! s:to_col(expr, lnum, char) abort
    let l:lines = getbufline(a:expr, a:lnum)
    if l:lines == []
        if type(a:expr) != v:t_string || !filereadable(a:expr)
            " invalid a:expr
            return a:char + 1
        endif
        " a:expr is a file that is not yet loaded as a buffer
        let l:lines = readfile(a:expr, '', a:lnum)
    endif
    let l:linestr = l:lines[-1]
    return strlen(strcharpart(l:linestr, 0, a:char)) + 1
endfunction

" The inverse version of `s:to_col`.
" Convert [lnum, col] to LSP's `Position`.
function! s:to_char(expr, lnum, col) abort
"{{{
    let l:lines = getbufline(a:expr, a:lnum)
    if l:lines == []
        if type(a:expr) != v:t_string || !filereadable(a:expr)
            " invalid a:expr
            return a:col - 1
        endif
        " a:expr is a file that is not yet loaded as a buffer
        let l:lines = readfile(a:expr, '', a:lnum)
    endif
    let l:linestr = l:lines[-1]
    return strchars(strpart(l:linestr, 0, a:col - 1))
"}}}
endfunction

function! ECY#utils#VimPostionToLSPPosition(expr, pos) abort
"{{{
    return {
         \   'line': a:pos[0] - 1,
         \   'character': s:to_char(a:expr, a:pos[0], a:pos[1])
         \ }
"}}}
endfunction

function! ECY#utils#LSPPositionToVimPostion(expr, position) abort
  let l:line = ECY#utils#LSPLineToVim(a:expr, a:position)
  let l:col = ECY#utils#LSPCharacterToVim(a:expr, a:position)
  return [l:line, l:col]
endfunction

function! ECY#utils#LSPLineToVim(expr, position) abort
  return a:position['line'] + 1
endfunction

function! ECY#utils#LSPCharacterToVim(expr, position) abort
"{{{
  let l:line = a:position['line'] + 1 " optimize function overhead by not calling lsp_line_to_vim
  let l:char = a:position['character']
  return s:to_col(a:expr, l:line, l:char)
"}}}
endfunction

function! ECY#utils#GetCurrentLineRange() abort
"{{{
  let l:pos = getpos('.')[1 : 2]
  let l:range = {}
  let l:range['start'] = ECY#utils#VimPostionToLSPPosition('%', l:pos)
  let l:range['end'] = ECY#utils#VimPostionToLSPPosition('%', [l:pos[0], l:pos[1] + strlen(getline(l:pos[0])) + 1])
  return l:range
"}}}
endfunction

function! ECY#utils#IsFileOpenedInVim(file_path, ...) abort
"{{{
  let l:buffer_nr = bufnr(a:file_path)
  if l:buffer_nr < 0 " not in vim
    return v:false
  endif
  if a:0 == 0
    return l:buffer_nr
  else
    return getbufline(l:buffer_nr, 1, "$")
  endif
"}}}
endfunction

function! ECY#utils#ChangeBuffer(buffer_path, context) abort
"{{{
  let l:buffer_nr = ECY#utils#IsFileOpenedInVim(a:buffer_path)
  if !l:buffer_nr " not in vim
    return
  endif

  for item in a:context['replace_line_list']
    call ECY#utils#Replace(l:buffer_nr, item['start_line'], item['end_line'], item['replace_list'])
  endfor
"}}}
endfunction

function! ECY#utils#ApplyTextEdit(context) abort
"{{{
  let l:cursor_pos = getcurpos()
  for item in keys(a:context)
    call ECY#utils#ChangeBuffer(item, a:context[item])
  endfor
  call cursor([l:cursor_pos[1], l:cursor_pos[2]])
"}}}
endfunction

function! ECY#utils#Replace(buffer_nr, start_line, end_line, replace_list) abort
"{{{
  call s:Delete(a:buffer_nr, a:start_line, a:end_line)
  call appendbufline(a:buffer_nr, a:start_line, a:replace_list) " 1-based
"}}}
endfunction

function! s:Delete(bufnr, start_line, end_line) abort
"{{{ 0-based
  let l:start_line = a:start_line + 1
  let l:end_line = a:end_line + 1
  if exists('*deletebufline')
    call deletebufline(a:bufnr, l:start_line, l:end_line) "1-based
  else
      let l:foldenable = &foldenable
      setlocal nofoldenable
      execute printf('%s,%sdelete _', l:start_line, l:end_line)
      let &foldenable = l:foldenable
  endif
"}}}
endfunction

function! s:Switch(path) abort
"{{{
  if bufnr(a:path) >= 0
    execute printf('keepalt keepjumps %sbuffer!', bufnr(a:path))
  else
    execute printf('keepalt keepjumps edit! %s', fnameescape(a:path))
  endif
"}}}
endfunction

function! ECY#utils#AskUserToSelete(content_list, callback_name) abort
"{{{
"}}}
endfunction

function! s:BufferList() abort
  return filter(range(1, bufnr('$')), 'buflisted(v:val) && getbufvar(v:val, "&filetype") != "qf"')
endfunction

function! s:GetBufferPathByID(buffer_nr) abort
"{{{
  let l:temp = getbufinfo(a:buffer_nr)
  if l:temp == []
    return ''
  endif
  return l:temp[0]['name']
"}}}
endfunction

function! ECY#utils#GetBufferPath() abort
"{{{
  let l:res = []
  for item in s:BufferList()
    let l:path = s:GetBufferPathByID(item)
    call add(l:res, l:path)
  endfor
  return l:res
"}}}
endfunction
