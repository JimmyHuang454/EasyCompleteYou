function! Output(msg) abort
  echon a:msg
endfunction

function! QuitVim() abort
  cquit!
endfunction

let g:repo_root = fnamemodify(expand('<sfile>'), ':h:h')

set encoding=utf-8
set termencoding=utf-8
set fileencoding=utf-8
scriptencoding utf-8

call Output('test end.')
call Output(g:repo_root)

call QuitVim()
