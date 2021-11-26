fun! ECY#goto#Init()
"{{{
  let g:ECY_is_unload_buffer_after_goto = get(g:,'ECY_is_unload_buffer_after_goto', v:true)
  let g:ECY_unload_buffer = {}

  augroup ECY_goto
    autocmd!
    autocmd QuitPre  * call s:WindowsLeave()
  augroup END
"}}}
endf

fun! s:WindowsLeave()
"{{{
  let l:buf_id = bufnr()
  if has_key(g:ECY_unload_buffer, l:buf_id)
    try
      call ECY#utils#DeleteBufferByID(l:buf_id)
    catch 
    endtry
    unlet g:ECY_unload_buffer[l:buf_id]
  endif
"}}}
endf

fun! s:AskWindowsStyle()
"{{{
  redraw!
  echo "Open Window by (v)ertical (h)orien (t)ab.\n>>"
  let l:style = input('Style: ')
  return l:style
"}}}
endf

fun! s:AskItem()
"{{{
  let s:show = ''
  let i = 1
  let l:uri = ''
  for item in s:res
    if has_key(item, 'uri')
      let l:uri = UriToPath(item['uri'])
    endif
    let s:show .= printf("%s. %s \n", string(i), l:uri)
    let i += 1
  endfor
  echo s:show
  let l:int = str2nr(input('Index: '))
  if l:int > len(s:res) || l:int == 0
    call ECY#utils#echo('Quited')
    return -1
  endif
  return l:int
"}}}
endf

fun! ECY#goto#Do(res) abort
  let s:res = a:res
  call s:Do()
endf

fun! s:Do() abort
"{{{
  if type(s:res) == v:t_list && len(s:res) == 0
    return
  endif

  if type(s:res) == v:t_dict
    
  else
    let l:int = 0
    if len(s:res) != 1
      let l:int = s:AskItem()
      if l:int == -1
        return
      endif
    endif

    let l:int -= 1
    let l:seleted = s:res[l:int]
    if !has_key(l:seleted, 'uri') || !has_key(l:seleted, 'range')
      call ECY#utils#echo('Wrong item.')
      return
    endif
    let l:path = UriToPath(l:seleted['uri'])
    let l:start = l:seleted['range']['start']
    let l:style = s:AskWindowsStyle()

    if bufnr(l:path) == -1 "file not in buffer.
      let l:is_new = v:true
    else
      let l:is_new = v:false
    endif

    let l:buffer_nr = 
          \ECY#utils#OpenFileAndMove(l:start['line'] + 1, l:start['character'], l:path, l:style)

    if l:is_new && g:ECY_is_unload_buffer_after_goto
      let g:ECY_unload_buffer[l:buffer_nr] = v:true
    endif
  endif
"}}}
endf
