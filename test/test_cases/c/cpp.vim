let g:ECY_is_debug = 1
let g:repo_root = fnamemodify(expand('<sfile>'), ':h:h:h:h')
let g:ECY_debug_log_file_path = expand('<sfile>') . '.ECY_log'
let g:log_file = expand('<sfile>') . '.log'
exe printf('so %s/test/startup.vim', g:repo_root)

let g:test_cpp = fnamemodify(expand('<sfile>'), ':h') . '/test.cpp'

function! s:T1() abort
    call OutputLine(g:test_cpp)
    call ECY#switch_engine#Set('cpp', 'ECY_engines.cpp.clangd.clangd')
    call ECY2_main#InstallLS('ECY_engines.cpp.clangd.clangd')
endfunction

function! s:T2() abort
    call ECY#utils#OpenFileAndMove(8, 12, g:test_cpp, 'h')
    call OutputLine(ECY#utils#GetCurrentBufferContent())
    call OutputLine(ECY#utils#GetCurrentLine())
    let &ft = 'cpp'
endfunction

function! s:T3() abort
    call Type("\<Esc>aty1")
endfunction

function! s:T4() abort
    call Type("\<Tab>")
endfunction

function! s:T5() abort
    call Expect(getline(8), '  test_abbr.type_1')
endfunction

function! s:T6() abort
endfunction

function! s:T7() abort
endfunction

call test_frame#Add({'event':[{'fuc': function('s:T1'), 'delay': 40000},
            \{'fuc': function('s:T2')},
            \{'fuc': function('s:T3'), 'delay': 20000},
            \{'fuc': function('s:T4')},
            \{'fuc': function('s:T5')},
            \]})

call test_frame#Run()
