
fun! s:Call(params)
  let l:event_name = a:params['event_name']
  let l:send_msg = {'event_name': l:event_name, 'params': {
                \'buffer_path': ECY#utility#GetCurrentBufferPath(), 
                \'buffer_line': GetCurrentLine(), 
                \'buffer_position': GetCurrentLineAndPosition(), 
                \'buffer_content': GetCurrentBufferContent(), 
                \'buffer_id': GetBufferIDChange()
                \}}
  call RPCEventsAll(l:send_msg)
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
"}}}
endf
