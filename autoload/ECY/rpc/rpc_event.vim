

fun! s:OnBufferEnter()
    call RPCEventsAll({'event_name': 'OnBufferEnter', 'params': {
                \'buffer_path': '', 
                \'buffer_id': s:GetBufferID()
                \}})
endf

fun! s:VimLeavePre()
    call RPCEventsAll({'event_name': 'VimLeavePre', 'params': {}})
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
    autocmd FileType      * call s:OnBufferEnter()
    autocmd BufEnter      * call s:OnBufferEnter()
    autocmd VimLeavePre   * call s:OnVIMLeave()

    " will send full buffer data to the server.
    " invoked after typing a character into the buffer or user sept in insert mode  
    autocmd TextChanged   * call s:OnTextChangedNormalMode()
    autocmd TextChangedI  * call s:OnTextChangedInsertMode()

    autocmd InsertLeave   * call s:OnInsertModeLeave()
    autocmd InsertEnter   * call s:OnInsertMode()
    autocmd InsertCharPre * call s:OnInsertChar()

    if g:has_floating_windows_support == 'vim'
      if !g:ECY_use_floating_windows_to_be_popup_windows
        " has floating windows, but user don't want to use it to be popup window
        autocmd CompleteChanged * call s:OnSelectingMenu_vim()
      endif
    elseif g:has_floating_windows_support == 'nvim'
      " TODO
    endif
  augroup END
"}}}
endf

call s:InitEvent()
