function! Output(msg) abort
  echon a:msg
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

call Output(g:repo_root . '\n')

let g:all_test_case = [g:repo_root . '/test/first_test.vim']


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                                  do test                                   "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
for test_case in g:all_test_case
  try
    exe 'so ' . test_case
  catch 
    call Output(test_case . ' Failded.')
  endtry
endfor


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                                    end                                     "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
call Output('test end.\n')
call QuitVim()
