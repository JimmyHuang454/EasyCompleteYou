fun! ECY#goto#Init()

endf

" {"jsonrpc":"2.0","result":[{"uri":"file:///C:/Users/qwer/Desktop/vimrc/myproject/test/go_hello_world/main.go","range":{"start":{"line":4,"character":1},"end":{"line":4,"character":6}}}],"id":306}
"
fun! ECY#goto#Do(res) abort
"{{{
  if type(a:res) == v:t_list && len(a:res) == 0
    return
  endif

  if type(a:res) == v:t_dict
    
  else
    let l:int = 0
    if len(a:res) != 1
      let s:show = ''
      let i = 1
      let l:uri = ''
      for item in a:res
        if has_key(item, 'uri')
          let l:uri = UriToPath(item['uri'])
        endif
        let s:show .= printf("%s. %s \n", string(i), l:uri)
        let i += 1
      endfor
      echo s:show
      let l:int = str2nr(input('Index: '))
      if l:int > len(a:res) || l:int == 0
        call ECY#utils#echo('Quited')
        return
      endif
    endif

    let l:seleted = a:res[l:int]
    if has_key(l:seleted, 'uri')
      call ECY#utils#echo(printf("Goto %s", UriToPath(l:seleted['uri'])))
    endif
    let l:path = UriToPath(l:seleted['uri'])
    let l:start = l:seleted['range']['start']
    call ECY#utils#MoveToBuffer(l:start['line'], l:start['character'], l:path, 'h')
  endif
"}}}
endf

function! ECY#utility#MoveToBuffer(line, colum, file_path, windows_to_show) abort
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

  if a:windows_to_show == 'h'
    exe 'new ' . a:file_path
    " horizontally new a windows at current tag
  elseif a:windows_to_show == 'v'
    " vertically new a windows at current tag
    exe 'vnew ' . a:file_path
  elseif a:windows_to_show == 't'
    " new a windows and new a tab
    exe 'tabedit '
    silent exe "hide edit " .  a:file_path
  elseif a:windows_to_show == 'to'
    " new a windows and a tab that can be a previous old one.
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
