fun! ECY#semantic_tokens#Init() abort
"{{{
  let g:ECY_enable_semantic_tokens = 
        \ECY#engine_config#GetEngineConfig('ECY', 'semantic_tokens.enable')

  let g:ECY_disable_semantic_tokens_in_insert_mode = 
        \ECY#engine_config#GetEngineConfig('ECY', 'semantic_tokens.disable_in_insert_mode')

  let g:ECY_semantic_tokens_info = {}
"}}}
endf

fun! ECY#semantic_tokens#RenderBuffer() abort
"{{{
  let l:buffer_path = ECY#utils#GetCurrentBufferPath()
  if !has_key(g:ECY_semantic_tokens_info, l:buffer_path) || 
        \!ECY2_main#IsWorkAtCurrentBuffer() || !g:ECY_enable_semantic_tokens
    return
  endif

  let l:start = line('w0') - 5
  let l:end = line('w$') + 5

  for item in g:ECY_semantic_tokens_info[l:buffer_path]['data']
    if l:start > item['line'] || item['line'] > l:end
      continue
    endif
    let l:line = item['line'] + 1
    let l:range = {'start': { 
          \'line': l:line, 'colum': item['start_colum'] },
          \'end' : { 'line': l:line, 'colum': item['end_colum']}}
    call ECY#utils#HighlightRange(l:range, item['color'])
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

fun! ECY#semantic_tokens#Update(context) abort
"{{{
  let l:path = a:context['path']
  let g:ECY_semantic_tokens_info[l:path] = a:context
  call ECY#semantic_tokens#RenderBuffer()
"}}}
endf
