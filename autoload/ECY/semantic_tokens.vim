fun! ECY#semantic_tokens#Init() abort
"{{{
  let g:ECY_enable_semantic_tokens = 
        \ECY#engine_config#GetEngineConfig('ECY', 'semantic_tokens.enable')

  let g:ECY_disable_semantic_tokens_in_insert_mode = 
        \ECY#engine_config#GetEngineConfig('ECY', 'semantic_tokens.disable_in_insert_mode')

  let g:ECY_semantic_tokens_info = {}

  let g:ECY_global_refresh_id = 1

  if !g:ECY_enable_semantic_tokens
    return
  endif

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

  if !has_key(g:ECY_semantic_tokens_info, l:current_path)
    return
  endif

  for item in g:ECY_semantic_tokens_info[l:current_path]['hl']
    call ECY#utils#UnHighlightRange(item)
  endfor

  let g:ECY_semantic_tokens_info[l:current_path]['hl'] = []
"}}}
endf

fun! ECY#semantic_tokens#Update(context) abort
"{{{
  if !g:ECY_enable_semantic_tokens
    return
  endif

  let l:path = a:context['path']
  if !has_key(g:ECY_semantic_tokens_info, l:path)
    let g:ECY_semantic_tokens_info[l:path] = {'hl': []}
  endif

  let g:ECY_semantic_tokens_info[l:path]['res'] = a:context
  call ECY#semantic_tokens#RenderBuffer()
"}}}
endf

fun! ECY#semantic_tokens#Do() abort
"{{{ normal and insert mode
  if !ECY2_main#IsWorkAtCurrentBuffer()
    return
  endif

  let l:params = {'buffer_path': ECY#utils#GetCurrentBufferPath(), 
                \'buffer_id': ECY#rpc#rpc_event#GetBufferIDChange()
                \}
  call ECY#rpc#rpc_event#call({'event_name': 'semanticTokens', 'params': l:params})
"}}}
endf

fun! ECY#semantic_tokens#AddRefreshID() abort
  let g:ECY_global_refresh_id += 1
endf

fun! ECY#semantic_tokens#Refresh() abort
"{{{
  if !exists('b:semantic_refresh_id')
    let b:semantic_refresh_id = 0
  endif

  if b:semantic_refresh_id != g:ECY_global_refresh_id
    call ECY#semantic_tokens#Do()
  endif

  let b:semantic_refresh_id = g:ECY_global_refresh_id
"}}}
endf
