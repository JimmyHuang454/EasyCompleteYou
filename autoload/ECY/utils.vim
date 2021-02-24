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
  return getbufline(bufnr(), 1, "$")
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

function! ECY#utils#StartLeaderfSelecting(content, callback_name) abort
"{{{
  try
    call leaderf_ECY#items_selecting#Start(a:content, a:callback_name)
  catch 
    call ECY#utility#ShowMsg("[ECY] You are missing 'Leaderf' or its version is too low. Please install/update it.", 2)
  endtry
"}}}
endfunction
