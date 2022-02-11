fun! ECY#semantic_tokens#Init() abort
"{{{
  let g:ECY_enable_semantic_tokens = 
        \ECY#engine_config#GetEngineConfig('ECY', 'semantic_tokens.enable')

  let g:ECY_disable_semantic_tokens_in_insert_mode = 
        \ECY#engine_config#GetEngineConfig('ECY', 'semantic_tokens.disable_in_insert_mode')

  let g:ECY_semantic_tokens_info = {}

  augroup ECY_Diagnosis
    autocmd CursorMoved * call s:CursorMoved()
    autocmd BufEnter * call s:BufEnter()
    autocmd InsertLeave * call s:InsertLeave()
  augroup END
"}}}
endf

fun! s:BufEnter() abort
  call ECY#semantic_tokens#RenderBuffer()
endf

fun! s:CursorMoved() abort
  call ECY#semantic_tokens#RenderBuffer()
endf

fun! s:InsertLeave() abort
  if !g:ECY_disable_semantic_tokens_in_insert_mode
    return
  endif

  call ECY#semantic_tokens#RenderBuffer()
endf

fun! ECY#semantic_tokens#RenderBuffer() abort
"{{{
  if g:ECY_disable_semantic_tokens_in_insert_mode && mode() == 'i'
    return
  endif

  call ECY#semantic_tokens#Clear() " will init 'hl' key

  let l:buffer_path = ECY#utils#GetCurrentBufferPath()
  if !has_key(g:ECY_semantic_tokens_info, l:buffer_path) || 
        \!ECY2_main#IsWorkAtCurrentBuffer() || !g:ECY_enable_semantic_tokens
    return
  endif

  let l:start = line('w0') - 5
  let l:end = line('w$') + 5

  for item in g:ECY_semantic_tokens_info[l:buffer_path]['res']['data']
    if l:start > item['line'] || item['line'] > l:end
      continue
    endif
    let l:line = item['line'] + 1
    let l:range = {'start': { 
          \'line': l:line, 'colum': item['start_colum'] },
          \'end' : { 'line': l:line, 'colum': item['end_colum']}}
    call add(g:ECY_semantic_tokens_info[l:buffer_path]['hl'], 
          \ECY#utils#HighlightRange(l:range, item['color']))
  endfor
"}}}
endf

fun! ECY#semantic_tokens#Clear() abort
"{{{
  let l:current_path = ECY#utils#GetCurrentBufferPath()

  for path in keys(g:ECY_semantic_tokens_info)
    if !g:is_vim && path != l:current_path
      continue
    endif

    if has_key(g:ECY_semantic_tokens_info[path], 'hl')
      for hl_id in g:ECY_semantic_tokens_info[path]['hl']
        call ECY#utils#MatchDelete(hl_id)
      endfor
    endif
  endfor

  if has_key(g:ECY_semantic_tokens_info, l:current_path)
    let g:ECY_semantic_tokens_info[l:current_path]['hl'] = []
  endif
"}}}
endf

fun! ECY#semantic_tokens#Update(context) abort
"{{{
  let l:path = a:context['path']
  if !has_key(g:ECY_semantic_tokens_info, l:path)
    let g:ECY_semantic_tokens_info[l:path] = {}
  endif

  let g:ECY_semantic_tokens_info[l:path]['res'] = a:context
  call ECY#semantic_tokens#RenderBuffer()
"}}}
endf
