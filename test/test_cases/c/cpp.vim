let g:ECY_is_debug = 1
let g:repo_root = fnamemodify(expand('<sfile>'), ':h:h:h:h')
let g:ECY_debug_log_file_path = expand('<sfile>') . '.ECY_log'
let g:log_file = expand('<sfile>') . '.log'
exe printf('so %s/test/startup.vim', g:repo_root)


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                               Switch engine                                "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:T1() abort
    new
    let &ft = 'cpp'
    call Type("\<Tab>")
endfunction

function! s:T2() abort
    call Type("jj")
endfunction

function! s:T3() abort
    call Type("\<Esc>")
    call Expect(ECY#switch_engine#GetBufferEngineName(), 'ECY_engines.cpp.clangd.clangd')

    call Expect(g:ECY_installer_config, {})
    call ECY2_main#InstallLS('ECY_engines.cpp.clangd.clangd')
endfunction


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                              test completion                               "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let g:test_cpp = fnamemodify(expand('<sfile>'), ':h') . '/test.cpp'
function! s:T4() abort
    call NotExpect(g:ECY_installer_config, {})

    call OutputLine(g:test_cpp)

    exe printf('new %s', g:test_cpp)
    call OutputLine(ECY#utils#GetCurrentBufferContent())
    call ECY#utils#MoveToBuffer(8, 13, g:test_cpp, 'h')
    call OutputLine(ECY#utils#GetCurrentLine())
    call Type("\<Esc>ach")
endfunction

function! s:T5() abort
    call Type("\<Tab>")
endfunction

function! s:T6() abort
    call Expect(getline(8), '  test_abbr.type_char')
endfunction

function! s:T7() abort
endfunction

call test_frame#Add({'event':[{'fuc': function('s:T1')}, 
            \{'fuc': function('s:T2')}, 
            \{'fuc': function('s:T3'), 'delay': 35000},
            \{'fuc': function('s:T4')},
            \{'fuc': function('s:T5')},
            \{'fuc': function('s:T6')},
            \{'fuc': function('s:T7')},
            \]})

call test_frame#Run()
