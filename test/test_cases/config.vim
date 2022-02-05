let g:ECY_config = {'ECY_engines.python.jedi_ls.jedi_ls':{'cmd': 'jedi-language-server'}}

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                                    init                                    "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let g:repo_root = fnamemodify(expand('<sfile>'), ':h:h:h')
let g:log_file = expand('<sfile>') . '.log'
exe printf('so %s/test/startup.vim', g:repo_root)

function! s:T1() abort
    call Expect(g:ECY_config['ECY_engines.python.jedi_ls.jedi_ls']['cmd'], 'jedi-language-server')
    call Expect(g:ECY_config['ECY_engines.python.jedi_ls.jedi_ls']['cmd2'], 'jedi-language-server')
    call Expect(g:ECY_config['ECY_engines.cpp.clangd.clangd']['cmd'], '')
endfunction

function! s:T2() abort
endfunction

function! s:T3() abort
endfunction

function! s:T4() abort
endfunction

function! s:T5() abort
endfunction

function! s:T6() abort
endfunction

function! s:T7() abort
endfunction

call test_frame#Add({'event':[{'fuc': function('s:T1')}, 
            \]})

call test_frame#Run()
