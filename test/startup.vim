function! OutputLine(msg) abort
  echon a:msg
  echon "\n"
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

let g:all_test_case = [g:repo_root . '/test/first_test.vim']


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                                  do test                                   "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
for test_case in g:all_test_case
  try
    exe 'so ' . test_case
  catch 
    call OutputLine(test_case . ' Failded.')
    echoerr 'sdf'
  endtry
endfor


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                                    end                                     "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
call OutputLine('test end.')
call QuitVim()
