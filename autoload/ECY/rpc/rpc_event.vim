fun! ECY#rpc#rpc_event#call(params)
"{{{
  if !ECY2_main#IsWorkAtCurrentBuffer()
    return
  endif

  let l:event_name = a:params['event_name']
  let l:params = a:params['params']

  if g:popup_windows_is_selecting && l:event_name == 'OnCompletion'
    let g:popup_windows_is_selecting = v:false
    return
  endif

  if !has_key(g:event_pre, l:event_name)
    let g:event_pre[l:event_name] = []
  endif

  if !has_key(g:event_callback, l:event_name)
    let g:event_callback[l:event_name] = []
  endif

  for Function in g:event_pre[l:event_name]
    call Function(l:event_name)
  endfor

  let l:send_msg = {'event_name': l:event_name, 'params': l:params}
  call ECY#rpc#rpc_main#RPCEventsAll(l:send_msg)

  for Function in g:event_pre[l:event_name]
    call Function(l:event_name)
  endfor
"}}}
endf

fun! ECY#rpc#rpc_event#AddEventCallbackPre(event_name, Function)
"{{{
  if !has_key(g:event_pre, a:event_name)
    let g:event_pre[a:event_name] = []
  endif
  call add(g:event_pre[l:event_name], a:Function)
"}}}
endf

fun! ECY#rpc#rpc_event#AddEventCallback(event_name, Function)
"{{{
  if !has_key(g:event_callback, a:event_name)
    let g:event_callback[a:event_name] = []
  endif
  call add(g:event_callback[l:event_name], a:Function)
"}}}
endf

fun! ECY#rpc#rpc_event#GetBufferIDNotChange()
"{{{
  let l:buffer_path = ECY#utils#GetCurrentBufferPath()
  if l:buffer_path == ''
    let l:buffer_path = 'nothing'
  endif
  if !has_key(g:ECY_buffer_version, l:buffer_path)
      let g:ECY_buffer_version[l:buffer_path] = 0
  endif
  return g:ECY_buffer_version[l:buffer_path]
"}}}
endf

fun! GetBufferIDByPath(path)
"{{{
  if !has_key(g:ECY_buffer_version, a:path)
    throw "Bad path."
  endif
  return g:ECY_buffer_version[a:path]
"}}}
endf

fun! ECY#rpc#rpc_event#GetBufferIDChange()
"{{{
  let l:buffer_path = ECY#utils#GetCurrentBufferPath()
  if l:buffer_path == ''
    let l:buffer_path = 'nothing'
  endif
  if !has_key(g:ECY_buffer_version, l:buffer_path)
      let g:ECY_buffer_version[l:buffer_path] = 0
  endif
  let g:ECY_buffer_version[l:buffer_path] += 1
  return g:ECY_buffer_version[l:buffer_path]
"}}}
endf

"{{{
fun! s:OnBufferEnter()
"{{{
  let l:params = {'buffer_path': ECY#utils#GetCurrentBufferPath(), 
                \'buffer_line': ECY#utils#GetCurrentLine(), 
                \'buffer_position': ECY#utils#GetCurrentLineAndPosition(), 
                \'buffer_content': ECY#utils#GetCurrentBufferContent(), 
                \'buffer_id': ECY#rpc#rpc_event#GetBufferIDNotChange()
                \}

  call ECY#rpc#rpc_event#call({'event_name': 'OnBufferEnter', 'params': l:params})
"}}}
endf

fun! s:OnVimLeavePre()
"{{{
  call ECY#rpc#rpc_event#call({'event_name': 'OnVimLeavePre', 'params': {}})
"}}}
endf

fun! s:OnTextChanged()
"{{{ normal and insert mode
  let l:params = {'buffer_path': ECY#utils#GetCurrentBufferPath(), 
                \'buffer_line': ECY#utils#GetCurrentLine(), 
                \'buffer_position': ECY#utils#GetCurrentLineAndPosition(), 
                \'buffer_content': ECY#utils#GetCurrentBufferContent(), 
                \'buffer_id': ECY#rpc#rpc_event#GetBufferIDChange()
                \}

  call ECY#rpc#rpc_event#call({'event_name': 'OnTextChanged', 'params': l:params})
"}}}
endf

fun! s:TextChangedI()
"{{{
  call s:OnTextChanged()
  call ECY#rpc#rpc_event#OnCompletion()
"}}}
endf

fun! s:InsertEnter()
"{{{
  call ECY#rpc#rpc_event#OnCompletion()
"}}}
endf

fun! ECY#rpc#rpc_event#OnCompletion()
"{{{
  let l:params = {'buffer_path': ECY#utils#GetCurrentBufferPath(), 
                \'buffer_line': ECY#utils#GetCurrentLine(), 
                \'buffer_position': ECY#utils#GetCurrentLineAndPosition(), 
                \'buffer_content': ECY#utils#GetCurrentBufferContent(), 
                \'buffer_id': ECY#rpc#rpc_event#GetBufferIDNotChange()
                \}

  call ECY#rpc#rpc_event#call({'event_name': 'OnCompletion', 'params': l:params})
"}}}
endf

fun! s:OnInsertLeave()
"{{{
  let l:params = {'buffer_path': ECY#utils#GetCurrentBufferPath(), 
                \'buffer_line': ECY#utils#GetCurrentLine(), 
                \'buffer_position': ECY#utils#GetCurrentLineAndPosition(), 
                \'buffer_content': ECY#utils#GetCurrentBufferContent(), 
                \'buffer_id': ECY#rpc#rpc_event#GetBufferIDNotChange()
                \}

  call ECY#rpc#rpc_event#call({'event_name': 'OnInsertLeave', 'params': l:params})
"}}}
endf
"}}}

fun! ECY#rpc#rpc_event#Init()
"{{{
  augroup EasyCompleteYou2
    autocmd!
    autocmd FileType      * call s:OnBufferEnter()
    autocmd BufEnter      * call s:OnBufferEnter()
    autocmd VimLeavePre   * call s:OnVimLeavePre()

    " will send full buffer data to the server.
    " invoked after typing a character into the buffer or user sept in insert mode  
    autocmd TextChanged   * call s:OnTextChanged()
    autocmd InsertLeave   * call s:OnInsertLeave()

    autocmd TextChangedI  * call s:TextChangedI()
    autocmd InsertEnter   * call s:InsertEnter()
  augroup END
  let g:event_pre = {}
  let g:event_callback = {}
"}}}
endf
