" Author: Jimmy Huang (1902161621@qq.com)
" License: WTFPL

fun! ECY#document_link#Init() abort
"{{{
  let g:ECY_enable_document_link = 
        \get(g:, 'ECY_enable_document_link', v:true)

  let g:ECY_document_link_info = {}

  hi ECY_document_link_style  term=underline gui=underline cterm=underline
  let g:ECY_document_link_style = get(g:,'ECY_document_link_style','ECY_document_link_style')

  if !g:ECY_enable_document_link
    return
  endif

  augroup ECY_document_link
    autocmd!
    autocmd InsertLeave   * call s:Update()
    autocmd BufEnter      * call s:Update()
    autocmd InsertEnter   * call s:InsertEnter()
  augroup END
"}}}
endf

fun! s:InsertEnter() abort " and selete with selete mode.
"{{{
  if !ECY2_main#IsWorkAtCurrentBuffer()
    return
  endif

  call ECY#document_link#ClearAll()
"}}}
endf

fun! ECY#document_link#RenderBuffer(buffer_path) abort
"{{{
  if ECY#utils#GetCurrentBufferPath() != a:buffer_path
    return
  endif
  if !has_key(g:ECY_document_link_info, a:buffer_path)
    return
  endif

  let l:info = g:ECY_document_link_info[a:buffer_path]
  let l:range = {'start': { 'line': 1, 'colum': 1 },'end' : { 'line': 2, 'colum': 1 } }
  call ECY#diagnostics#HighlightRange(l:range, 'ECY_document_link_style')
"}}}
endf

fun! ECY#document_link#ClearAll() abort
"{{{
  for l:match in getmatches()
    if l:match['group'] =~# '^ECY_document_link_style'
        call matchdelete(l:match['id'])
    endif
  endfor
"}}}
endf

fun! s:Update() abort " and selete with selete mode.
"{{{
  if !ECY2_main#IsWorkAtCurrentBuffer()
    return
  endif

  call ECY#document_link#ClearAll()

  let l:params = {'buffer_path': ECY#utils#GetCurrentBufferPath(), 
                \'buffer_id': ECY#rpc#rpc_event#GetBufferIDNotChange()
                \}

  call ECY#rpc#rpc_event#call({'event_name': 'DocumentLink', 'params': l:params})
"}}}
endf

fun! ECY#document_link#Do(res) abort " Update
"{{{
  let l:buffer_path = a:res['buffer_path']
  let l:buffer_id = a:res['buffer_id']
  if ECY#rpc#rpc_event#GetBufferIDByPath(l:buffer_path) > l:buffer_id
    return
  endif

  let g:ECY_document_link_info[l:buffer_path] = a:res

  call ECY#document_link#RenderBuffer(ECY#utils#GetCurrentBufferPath())
"}}}
endf

