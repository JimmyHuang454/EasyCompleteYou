

fun! s:Call(params)
    call RPCEventsAll({'event_name': a:params['event_name'], 'params': {
                \'buffer_path': '', 
                \'buffer_id': s:GetBufferID()
                \}})
endf

fun! s:GetBufferID()
    if !exists('b:buffer_id')
        let b:buffer_id = 0
    endif
    let b:buffer_id += 1
    return b:buffer_id
endf

fun! s:InitEvent()
"{{{
  augroup EasyCompleteYou
    autocmd!
    autocmd FileType      * call s:Call({'event_name': 'OnBufferEnter'})
    autocmd BufEnter      * call s:Call({'event_name': 'OnBufferEnter'})
    autocmd VimLeavePre   * call s:Call({'event_name': 'OnVimLeavePre'})

    " will send full buffer data to the server.
    " invoked after typing a character into the buffer or user sept in insert mode  
    autocmd TextChanged   * call s:Call({'event_name': 'OnTextChanged'})
    autocmd TextChangedI  * call s:Call({'event_name': 'OnTextChangedI'})

    autocmd InsertLeave   * call s:Call({'event_name': 'OnInsertLeave'})
    autocmd InsertEnter   * call s:Call({'event_name': 'OnVimInsertEnter'})
  augroup END
"}}}
endf

call s:InitEvent()
