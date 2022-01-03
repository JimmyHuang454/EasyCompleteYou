let g:ECY_engine_config = {'ECY_engines.python.jedi_ls.jedi_ls':{'cmd': 'jedi-language-server'}}

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                                    init                                    "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

let g:repo_root = fnamemodify(expand('<sfile>'), ':h:h:h')
let g:log_file = expand('<sfile>') . '.log'
exe printf('so %s/test/startup.vim', g:repo_root)

function! s:T1() abort
    new
    let &ft = 'python'
    call Expect(ECY#switch_engine#GetBufferEngineName(), 'ECY.engines.default_engine')
    call Type("\<Tab>")
endfunction

function! s:T2() abort
    call Type("jjj\<Esc>")
endfunction

function! s:T3() abort
    call Expect(ECY#switch_engine#GetBufferEngineName(), 'ECY_engines.python.jedi_ls.jedi_ls')
    call Type("iimpor\<Esc>")
endfunction

function! s:T4() abort
    call Type("a")
endfunction

function! s:T5() abort
    call Type("\<Tab>")
endfunction

function! s:T6() abort
    call Expect(getline(1), 'import')
endfunction

call test_frame#Add({'event':[{'fuc': function('s:T1')}, 
            \{'fuc': function('s:T2')}, 
            \{'fuc': function('s:T3')},
            \{'fuc': function('s:T4')},
            \{'fuc': function('s:T5')},
            \{'fuc': function('s:T6')},
            \]})
call test_frame#Run()
