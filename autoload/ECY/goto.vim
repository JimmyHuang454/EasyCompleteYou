fun! ECY#goto#Init()
"{{{
  let g:ECY_is_unload_buffer_after_goto = 
        \ECY#engine_config#GetEngineConfig('ECY', 'goto.unload_buffer_after_goto')

  let g:ECY_unload_buffer = {}

  augroup ECY_goto
    autocmd!
    autocmd QuitPre  * call s:WindowsLeave()
  augroup END
"}}}
endf

fun! s:WindowsLeave()
"{{{
  if !g:ECY_is_unload_buffer_after_goto
    return
  endif

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
  let l:index = str2nr(input('Index: '))
  if l:index > len(s:res) || l:index == 0
    call ECY#utils#echo('Quited')
    return -1
  endif
  return l:index
"}}}
endf

fun! ECY#goto#Open(res) abort
  let s:res = a:res
  call s:OpenQF()
endf

fun! s:OpenQF() abort
  let l:res = []
  for item in s:res
    let l:temp = item['path']
    let l:pos = ''
    if has_key(item, 'range')
      let l:pos .= printf(' [L-%s, C-%s]', 
            \item['range']['start']['line'], item['range']['start']['character'])
    endif
    let item['abbr'] = [{'value': item['path']}, {'value': l:pos, 'hl': 'LineNr'}]
  endfor
  call ECY#qf#Open(s:res, {})
endf


fun! ECY#goto#Preview(res) abort
  let s:res = a:res
  call s:Preview()
endf

fun! s:Open() abort
"{{{
  if type(s:res) == v:t_list && len(s:res) == 0
    return
  endif

  if type(s:res) == v:t_dict
    
  else
    let l:index = 0
    if len(s:res) != 1
      let l:index = s:AskItem()
      if l:index == -1
        return
      endif
    endif

    let l:index -= 1
    let l:seleted = s:res[l:index]
    if !has_key(l:seleted, 'uri') || !has_key(l:seleted, 'range') || 
          \!has_key(l:seleted, 'path')
      call ECY#utils#echo('Wrong item.')
      return
    endif
    let l:path = l:seleted['path']
    let l:start = l:seleted['range']['start']
    let l:style = ECY#utils#AskWindowsStyle()

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

fun! s:Preview() abort
"{{{
  if type(s:res) == v:t_list && len(s:res) == 0
    return
  endif

  if type(s:res) == v:t_dict
    
  else
    let l:index = 0
    if len(s:res) != 1
      let l:index = s:AskItem()
      if l:index == -1
        return
      endif
    endif

    let l:index -= 1
    let l:seleted = s:res[l:index]
    if !has_key(l:seleted, 'uri') || !has_key(l:seleted, 'range') || 
          \!has_key(l:seleted, 'path')
      call ECY#utils#echo('Wrong item.')
      return
    endif

    let l:path = l:seleted['path']
    let l:start = l:seleted['range']['start']

    let l:opts = {'syntax': &syn, 'title': l:path}
    " TODO
    return
    let l:win_id = quickui#preview#open(l:path, l:opts)
    call quickui#utils#set_firstline(l:win_id, l:start['line'] + 1)
  endif
"}}}
endf
