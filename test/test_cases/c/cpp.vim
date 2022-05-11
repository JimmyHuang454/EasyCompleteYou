let g:ECY_is_debug = 1
let g:repo_root = fnamemodify(expand('<sfile>'), ':h:h:h:h')
let g:ECY_debug_log_file_path = expand('<sfile>') . '.ECY_log'
let g:log_file = expand('<sfile>') . '.log'
exe printf('so %s/test/startup.vim', g:repo_root)

let g:test_cpp = fnamemodify(expand('<sfile>'), ':h') . '/test.cpp'

function! s:T1() abort
    call OutputLine(g:test_cpp)
    call ECY#engine#Set('cpp', 'ECY_engines.cpp.clangd.clangd')
    call ECY2_main#InstallLS('ECY_engines.cpp.clangd.clangd')
endfunction

function! s:T2() abort
    call OutputLine(string(g:ECY_installer_config))
    call ECY#utils#OpenFileAndMove(11, 13, g:test_cpp, 'h')
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
    call Expect(getline(11), '  test_abbr2.type_1')
endfunction

function! s:T6() abort
    call ECY#utils#OpenFileAndMove(19, 12, g:test_cpp, 'h')
    call Type("\<Esc>aty1")
endfunction

function! s:T7() abort
    call Type("\<Tab>")
endfunction

function! s:T8() abort
    call Expect(getline(19), '  test_abbr.type_1')
endfunction

call test_frame#Add({'event':[{'fuc': function('s:T1'), 'delay': 40000},
            \{'fuc': function('s:T2')},
            \{'fuc': function('s:T3'), 'delay': 20000},
            \{'fuc': function('s:T4')},
            \{'fuc': function('s:T5')},
            \{'fuc': function('s:T6'), 'delay': 20000},
            \{'fuc': function('s:T7')},
            \{'fuc': function('s:T8')},
            \]})

call test_frame#Run()
