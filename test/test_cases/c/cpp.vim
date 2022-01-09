" XXXX
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
    exe printf('new %s', g:test_cpp)
    let &ft = 'cpp'
    call OutputLine(ECY#utils#GetCurrentBufferContent())
    call ECY#utils#MoveToBuffer(8, 12, g:test_cpp, 'h')
    call OutputLine(ECY#utils#GetCurrentLine())
endfunction

function! s:T3() abort
    call Type("\<Esc>ach")
endfunction

function! s:T4() abort
    call Type("\<Tab>")
endfunction

function! s:T5() abort
    call Expect(getline(8), '  test_abbr.type_char')
endfunction

function! s:T6() abort
endfunction

function! s:T7() abort
endfunction

call test_frame#Add({'event':[{'fuc': function('s:T1'), 'delay': 45000},
            \{'fuc': function('s:T2')},
            \{'fuc': function('s:T3')},
            \{'fuc': function('s:T4')},
            \{'fuc': function('s:T5')},
            \{'fuc': function('s:T6')},
            \{'fuc': function('s:T7')},
            \]})

call test_frame#Run()
