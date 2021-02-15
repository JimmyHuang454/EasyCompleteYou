fun! utils#echo(msg)
  echo a:msg
endf

function! utils#GetCurrentBufferPath(...) abort
"{{{
  " let l:full_path = fnamemodify(@%, ':p')
  let l:full_path = expand('%:p')
  return l:full_path
"}}}
endfunction

function utils#GetCurrentBufferPosition() abort
"{{{ utf-8]
  return { 'line': line('.') - 1, 'colum': col('.') - 1}
"}}}
endfunction

function utils#GetCurrentLineAndPosition() abort
"{{{
  let l:temp = utils#GetCurrentBufferPosition()
  let l:temp['line_content'] = getline(".")
  return l:temp
"}}}
endfunction

function utils#GetCurrentLine() abort
"{{{
  return getline(".")
"}}}
endfunction

function utils#GetCurrentBufferContent() abort " return list
"{{{
  return getbufline(bufnr(), 1, "$")
"}}}
endfunction

function DefineColor(name, colora) abort
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

function! MoveToBuffer(line, colum, file_path, windows_to_show) abort
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
    if utils#GetCurrentBufferPath() != a:file_path
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

function! utils#SendKeys(keys) abort
"{{{
  call feedkeys( a:keys, 'in' )
"}}}
endfunction

function! utils#GetValue(dicts, key, default_value) abort 
"{{{
  if !has_key(a:dicts, a:key)
    return a:default_value
  endif
  return a:dicts[a:key]
"}}}
endfunction
