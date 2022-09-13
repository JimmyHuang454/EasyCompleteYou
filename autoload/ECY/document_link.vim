" Author: Jimmy Huang (1902161621@qq.com)
" License: WTFPL

fun! ECY#document_link#Init() abort
"{{{
  let g:ECY_enable_document_link = 
        \ECY#engine_config#GetEngineConfig('ECY', 'lsp.document_link.enable')

  let g:ECY_disable_document_link_in_insert_mode = 
        \ECY#engine_config#GetEngineConfig('ECY', 'lsp.document_link.disable_in_insert_mode')

  hi ECY_document_link_style  term=underline gui=underline cterm=underline
  let g:ECY_document_link_style = 
        \ECY#engine_config#GetEngineConfig('ECY', 'lsp.document_link.highlight_style')

  let g:ECY_document_link_info = {}
"}}}
endf

fun! ECY#document_link#RenderCurrentBuffer() abort
"{{{
  call ECY#document_link#ClearAll()

  let l:buffer_path = ECY#utils#GetCurrentBufferPath()
  if !has_key(g:ECY_document_link_info, l:buffer_path)
    return
  endif

  let l:info = g:ECY_document_link_info[l:buffer_path]

  for item in l:info['data']['res']
    let l:temp = item['range']
    let l:range = {'start': { 
          \'line': l:temp['start']['line'] + 1, 'colum': l:temp['start']['character'] },
          \'end' : { 'line': l:temp['end']['line'] + 1, 'colum': l:temp['end']['character']}}
    call add(l:info['hl'], ECY#utils#HighlightRange(l:range, 'ECY_document_link_style'))
  endfor
"}}}
endf

fun! ECY#document_link#ClearAll() abort
"{{{
  let l:buffer_path = ECY#utils#GetCurrentBufferPath()
  if !has_key(g:ECY_document_link_info, l:buffer_path)
    return
  endif

  for item in g:ECY_document_link_info[l:buffer_path]['hl']
    call ECY#utils#UnHighlightRange(item)
  endfor

  let g:ECY_document_link_info[l:buffer_path]['hl'] = []
"}}}
endf

fun! ECY#document_link#Do(res) abort " Update
"{{{
  if !g:ECY_enable_document_link
    return
  endif

  let l:buffer_path = a:res['buffer_path']
  let l:buffer_id = a:res['buffer_id']
  if ECY#rpc#rpc_event#GetBufferIDByPath(l:buffer_path) > l:buffer_id
    return
  endif

  if !has_key(g:ECY_document_link_info, l:buffer_path)
    let g:ECY_document_link_info[l:buffer_path] = {'hl': []}
  endif

  let g:ECY_document_link_info[l:buffer_path]['data'] = a:res

  call ECY#document_link#RenderCurrentBuffer()
"}}}
endf

fun! ECY#document_link#Open() abort
"{{{
  if !g:ECY_enable_document_link
    return
  endif

  let l:buffer_path = ECY#utils#GetCurrentBufferPath()

  if !has_key(g:ECY_document_link_info, l:buffer_path)
    return
  endif

  let l:info = g:ECY_document_link_info[l:buffer_path]

  for item in l:info['res']
    let l:res = item
    let l:range = item['range']
    let l:line  = line('.') - 1
    let l:col   = col('.')
    if l:range['start']['line'] <= l:line && l:range['end']['line'] >= l:line &&
          \l:range['start']['character'] <= l:col && l:range['end']['character']  >= l:col
      break
    endif
  endfor

  let l:style = ECY#utils#AskWindowsStyle()
  call ECY#utils#OpenFileAndMove(1, 1, l:res['target']['path'], l:style)
"}}}
endf
