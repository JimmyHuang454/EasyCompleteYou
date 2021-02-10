fun! utils#echo(msg)
  echo a:msg
endf

function GetCurrentBufferPosition() abort
"{{{ utf-8]
  return { 'line': line('.') - 1, 'colum': col('.') - 1}
"}}}
endfunction

function GetCurrentLineAndPosition() abort
"{{{
  let l:temp = GetCurrentBufferPosition()
  let l:temp['line_content'] = getline(".")
  return l:temp
"}}}
endfunction

function GetCurrentLine() abort
"{{{
  return getline(".")
"}}}
endfunction

function GetCurrentBufferContent() abort " return list
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
  try
    call prop_type_add(a:name, {'highlight': a:name}) " vim
  catch 
  endtry
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
    if ECY#utility#GetCurrentBufferPath() != a:file_path
      silent exe "hide edit " .  a:file_path
    endif
  endif
  call cursor(a:line, a:colum + 1)
"}}}
endfunction
