fun! ECY#rpc#rpc_event#call(context)
"{{{
  if !ECY2_main#IsWorkAtCurrentBuffer()
    return
  endif

  let l:event_name = a:context['event_name']
  let l:params = a:context['params']

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

  let l:params['event_name'] = l:event_name
  let l:send_msg = {'event_name': l:event_name, 'params': l:params}
  if has_key(a:context, 'engine_name')
    let l:engine_name = a:context['engine_name']
  else
    let l:engine_name = ECY#engine#GetBufferEngineName()
  endif
  call ECY#rpc#rpc_main#RPCEventsAll(l:send_msg, l:engine_name)

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

"{{{buffer version
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

fun! ECY#rpc#rpc_event#GetBufferIDByPath(path)
"{{{
  if has_key(g:ECY_buffer_version, a:path)
    return g:ECY_buffer_version[a:path]
  endif
  return 0
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
"}}}

"{{{event functions
fun! ECY#rpc#rpc_event#OnBufferEnter()
"{{{
  if !ECY2_main#IsWorkAtCurrentBuffer()
    return
  endif
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
  if !ECY2_main#IsWorkAtCurrentBuffer()
    return
  endif

  let l:params = {'buffer_path': ECY#utils#GetCurrentBufferPath(), 
                \'buffer_line': ECY#utils#GetCurrentLine(), 
                \'buffer_position': ECY#utils#GetCurrentLineAndPosition(), 
                \'buffer_content': ECY#utils#GetCurrentBufferContent(), 
                \'change_mode': mode(), 
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

fun! s:BufWritePost()
"{{{
  if !ECY2_main#IsWorkAtCurrentBuffer()
    return
  endif
  
  let l:params = {'buffer_path': ECY#utils#GetCurrentBufferPath(), 
                \'buffer_id': ECY#rpc#rpc_event#GetBufferIDNotChange()
                \}

  call ECY#rpc#rpc_event#call({'event_name': 'OnSave', 'params': l:params})
"}}}
endf

fun! ECY#rpc#rpc_event#OnCompletion()
"{{{
  if ECY#engine#GetBufferEngineName() == 'ECY_engines.vim_lsp.vim_lsp'
    call ECY#vim_lsp#main#Request()
    return
  endif

  if !ECY2_main#IsWorkAtCurrentBuffer() || !g:ECY_completion_enable
    return
  endif
  
  let l:params = {'buffer_path': ECY#utils#GetCurrentBufferPath(), 
                \'buffer_line': ECY#utils#GetCurrentLine(), 
                \'buffer_position': ECY#utils#GetCurrentLineAndPosition(), 
                \'time_stamp': reltimefloat(reltime()), 
                \'buffer_id': ECY#rpc#rpc_event#GetBufferIDNotChange()
                \}

  call ECY#rpc#rpc_event#call({'event_name': 'OnCompletion', 'params': l:params})
"}}}
endf

fun! ECY#rpc#rpc_event#OnInsertLeave()
"{{{
  if !ECY2_main#IsWorkAtCurrentBuffer()
    return
  endif
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
    autocmd FileType      * call ECY#rpc#rpc_event#OnBufferEnter()
    autocmd BufEnter      * call ECY#rpc#rpc_event#OnBufferEnter()
    autocmd VimLeavePre   * call s:OnVimLeavePre()

    " will send full buffer data to the server.
    " invoked after typing a character into the buffer or user sept in insert mode  
    autocmd TextChanged   * call s:OnTextChanged()
    autocmd InsertLeave   * call ECY#rpc#rpc_event#OnInsertLeave()

    autocmd TextChangedI * call s:TextChangedI()
    autocmd InsertEnter  * call s:InsertEnter()
    autocmd BufWritePost * call s:BufWritePost()
  augroup END

  let g:event_pre = {}
  let g:event_callback = {}
  let g:ECY_buffer_version = {}
"}}}
endf
