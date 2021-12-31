function! OutputLine(msg) abort
  let g:log_info .= a:msg . "\n"
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
  call writefile(split(g:log_info, "\n"), g:log_file, 'b')
  qall!
endfunction

function! AddLine(str)
  put! =a:str
endfunction

function AddRTP(path) abort
  if isdirectory(a:path)
    let path = substitute(a:path, '\\\+', '/', 'g')
    let path = substitute(path, '/$', '', 'g')
    let &runtimepath = escape(path, '\,') . ',' . &runtimepath
    let after = path . '/after'
    if isdirectory(after)
      let &runtimepath .= ',' . after
    endif
  endif
endfunction

function SoPath(path) abort
  exe 'so ' . a:path
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                                    init                                    "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let g:repo_root = fnamemodify(expand('<sfile>'), ':h:h')
let g:log_info = ''
call AddRTP(g:repo_root)
call SoPath(printf('so %s/plugin/easycompleteyou2.vim', g:repo_root))

set encoding=utf-8
set termencoding=utf-8
set fileencoding=utf-8
scriptencoding utf-8

call OutputLine(g:repo_root)
call SoPath(printf('so %s/test/test_frame.vim', g:repo_root))
