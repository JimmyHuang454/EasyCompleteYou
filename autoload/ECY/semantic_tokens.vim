fun! ECY#semantic_tokens#Init() abort
"{{{
  let g:ECY_enable_semantic_tokens = 
        \ECY#engine_config#GetEngineConfig('ECY', 'semantic_tokens.enable')

  let g:ECY_disable_semantic_tokens_in_insert_mode = 
        \ECY#engine_config#GetEngineConfig('ECY', 'semantic_tokens.disable_in_insert_mode')

  let g:ECY_semantic_tokens_info = {}
"}}}
endf

fun! s:RenderBuffer() abort
"{{{
  let l:buffer_path = ECY#utils#GetCurrentBufferPath()
  if !has_key(g:ECY_semantic_tokens_info, l:buffer_path) || 
        \!ECY2_main#IsWorkAtCurrentBuffer() || !g:ECY_enable_semantic_tokens
    return
  endif

  let l:start = line('w0') - 5
  let l:end = line('w$') + 5

  for item in g:ECY_semantic_tokens_info[l:buffer_path]
    if l:start > item['line'] || item['line'] > l:end
      continue
    endif
    let l:line = item['line'] + 1
    let l:range = {'start': { 
          \'line': l:line, 'colum': item['start_colum'] },
          \'end' : { 'line': l:line, 'colum': item['end_colum']}}
    let l:color = 'ECY_semantic_tokens_' . item['color']
    call ECY#utils#HighlightRange(l:range, l:color)
  endfor
"}}}
endf

fun! ECY#semantic_tokens#Clear() abort
"{{{
  for l:match in getmatches()
    if l:match['group'] =~# '^ECY_semantic_tokens'
        call matchdelete(l:match['id'])
    endif
  endfor
"}}}
endf

fun! ECY#semantic_tokens#Do(context) abort
"{{{
  let l:path = a:context['path']
  let g:ECY_semantic_tokens_info[l:path] = a:context
  call s:RenderBuffer()
"}}}
endf

fun! ECY#semantic_tokens#ShowCmd()
"{{{ show all
  let l:buffer_path = ECY#utils#GetCurrentBufferPath()
  if !has_key(g:ECY_semantic_tokens_info, l:buffer_path) || 
        \!ECY2_main#IsWorkAtCurrentBuffer() || !g:ECY_enable_semantic_tokens
    return
  endif

  let s:show = ''
  let l:res = g:ECY_semantic_tokens_info[l:buffer_path]['res']
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
