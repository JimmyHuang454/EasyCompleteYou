function! OutputLine(msg) abort
  echon a:msg
  echon "\n"
endfunction

function! Expect(value, expected) abort
  if a:value != a:expected
    call OutputLine('Failded')
    call OutputLine(printf('Extended: "%s"', a:expected))
    call OutputLine(printf('Actual: "%s"', a:value))
    throw "Wrong case."
  else
    call OutputLine('OK.')
  endif
endfunction

function! QuitVim() abort
  cquit!
endfunction

function! AddLine(str)
  put! =a:str
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                                    init                                    "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let g:repo_root = fnamemodify(expand('<sfile>'), ':h:h')

set encoding=utf-8
set termencoding=utf-8
set fileencoding=utf-8
scriptencoding utf-8

call OutputLine(g:repo_root)
exe printf('so %s/test/test_frame.vim', g:repo_root)
