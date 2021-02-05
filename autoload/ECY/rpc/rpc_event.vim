fun! s:Call(params)
"{{{

  let l:event_name = a:params['event_name']

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

  let l:send_msg = {'event_name': l:event_name, 'params': {
                \'buffer_path': ECY#utility#GetCurrentBufferPath(), 
                \'buffer_line': GetCurrentLine(), 
                \'buffer_position': GetCurrentLineAndPosition(), 
                \'buffer_content': GetCurrentBufferContent(), 
                \'buffer_id': GetBufferIDChange()
                \}}
  call RPCEventsAll(l:send_msg)

  for Function in g:event_pre[l:event_name]
    call Function(l:event_name)
  endfor
"}}}
endf

fun! AddEventCallbackPre(event_name, Function)
"{{{
  if !has_key(g:event_pre, a:event_name)
    let g:event_pre[a:event_name] = []
  endif
  call add(g:event_pre[l:event_name], a:Function)
"}}}
endf

fun! AddEventCallback(event_name, Function)
"{{{
  if !has_key(g:event_callback, a:event_name)
    let g:event_callback[a:event_name] = []
  endif
  call add(g:event_callback[l:event_name], a:Function)
"}}}
endf

fun! GetBufferIDChange()
    if !exists('b:buffer_id')
        let b:buffer_id = 0
    endif
    let b:buffer_id += 1
    return b:buffer_id
endf

fun! RPCInitEvent()
"{{{
  augroup EasyCompleteYou2
    autocmd!
    autocmd FileType      * call s:Call({'event_name': 'OnBufferEnter'})
    autocmd BufEnter      * call s:Call({'event_name': 'OnBufferEnter'})
    autocmd VimLeavePre   * call s:Call({'event_name': 'OnVimLeavePre'})

    " will send full buffer data to the server.
    " invoked after typing a character into the buffer or user sept in insert mode  
    autocmd TextChanged   * call s:Call({'event_name': 'OnTextChanged'})
    autocmd TextChangedI  * call s:Call({'event_name': 'OnCompletion'})

    autocmd InsertLeave   * call s:Call({'event_name': 'OnInsertLeave'})
    autocmd InsertEnter   * call s:Call({'event_name': 'OnCompletion'})
  augroup END
  let g:event_pre = {}
  let g:event_callback = {}
"}}}
endf
