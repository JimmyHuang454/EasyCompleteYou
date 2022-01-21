fun! ECY#code_lens#Init() abort
"{{{
  let g:ECY_enable_code_lens = 
        \get(g:, 'ECY_enable_code_lens', v:true)

  let g:ECY_disable_code_lens_in_insert_mode = 
        \get(g:, 'ECY_disable_code_lens_in_insert_mode', v:true)

  let g:ECY_code_lens_info = {}
"}}}
endf

fun! s:RenderBuffer() abort
"{{{
  let l:buffer_path = ECY#utils#GetCurrentBufferPath()
  if !has_key(g:ECY_code_lens_info, l:buffer_path) || 
        \!ECY2_main#IsWorkAtCurrentBuffer() || !g:ECY_enable_code_lens
    return
  endif

"}}}
endf

fun! ECY#code_lens#Do(context) abort
"{{{
  let l:path = a:context['path']
  let g:ECY_code_lens_info[l:path] = a:context
  call s:RenderBuffer()
"}}}
endf

fun! ECY#code_lens#ShowCmd()
"{{{ show all
  let l:buffer_path = ECY#utils#GetCurrentBufferPath()
  if !has_key(g:ECY_code_lens_info, l:buffer_path) || 
        \!ECY2_main#IsWorkAtCurrentBuffer() || !g:ECY_enable_code_lens
    return
  endif

  let s:show = ''
  let l:res = g:ECY_code_lens_info[l:buffer_path]['res']
  let i = 1
  let l:uri = ''
  for item in l:res
    let l:command = 'NoName'
    if has_key(item, 'command')
      let l:command = item['command']['title']
    endif

    let s:show .= printf("%s. %s \n", string(i), l:command)
    let i += 1
  endfor
  echo s:show
  let l:index = str2nr(input('Index: '))
  if l:index > len(l:res) || l:index == 0
    call ECY#utils#echo('Quited')
    return -1
  endif
  return l:index
"}}}
endf
