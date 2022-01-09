let g:ECY_is_debug = 1
let g:ECY_debug_log_file_path = expand('<sfile>') . '.ECY_log'

let g:log_file = expand('<sfile>') . '.log'
let g:repo_root = fnamemodify(expand('<sfile>'), ':h:h:h:h')
exe printf('so %s/test/startup.vim', g:repo_root)


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                               Switch engine                                "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:T1() abort
    new
    let &ft = 'python'
    call Type("\<Tab>")
endfunction

function! s:T2() abort
    call Type("jjj")
endfunction

function! s:T3() abort
    call Type("\<Esc>")
endfunction


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                              test completion                               "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let g:test_cpp = fnamemodify(expand('<sfile>'), ':h') . '/test.py'
function! s:T4() abort
    call Expect(ECY#switch_engine#GetBufferEngineName(), 'ECY_engines.python.jedi_ls.jedi_ls')
    call OutputLine(g:test_cpp)

    call ECY#utils#MoveToBuffer(1, 5, g:test_cpp, 'h')
    call OutputLine(ECY#utils#GetCurrentBufferContent())
    let &ft = 'python'

    call OutputLine(ECY#utils#GetCurrentLine())
endfunction

function! s:T5() abort
    call Type("\<Esc>a")
endfunction

function! s:T6() abort
    call Type("\<Tab>")
endfunction

function! s:T7() abort
    call Expect(getline(1), 'import')
endfunction

call test_frame#Add({'event':[{'fuc': function('s:T1')}, 
            \{'fuc': function('s:T2')}, 
            \{'fuc': function('s:T3')},
            \{'fuc': function('s:T4')},
            \{'fuc': function('s:T5'), 'delay': 15000},
            \{'fuc': function('s:T6')},
            \{'fuc': function('s:T7')},
            \]})

call test_frame#Run()
