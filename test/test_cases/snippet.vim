let g:repo_root = fnamemodify(expand('<sfile>'), ':h:h:h')
let g:log_file = expand('<sfile>') . '.log'
exe printf('so %s/test/startup.vim', g:repo_root)


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                                    init                                    "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let g:UltiSnipsExpandTrigger = "<A-d>"

" call OutputLine(g:repo_root . '/snippets')
" call AddRTP(g:repo_root . '/snippets')
" call SoPath(printf('%s/plugin/vimsnippets.vim', g:repo_root . '/snippets'))

" call AddRTP(g:repo_root . '/ultisnips')
" call SoPath(printf('%s/plugin/UltiSnips.vim', g:repo_root . '/ultisnips'))

function! s:T1() abort
    call Expect(ECY#switch_engine#GetBufferEngineName(), 'ECY.engines.default_engine')
    call Type("\<Tab>")
endfunction

function! s:T2() abort
    call Type("jjj")
endfunction

function! s:T3() abort
    call Expect(ECY#switch_engine#GetBufferEngineName(), 'ECY_engines.snippet.ultisnips.ultisnips')
endfunction

function! s:T4() abort
endfunction

function! s:T5() abort
endfunction

call test_frame#Add({'event':[{'fuc': function('s:T1')}, 
            \{'fuc': function('s:T2')}, 
            \{'fuc': function('s:T3')},
            \{'fuc': function('s:T4')},
            \{'fuc': function('s:T5')},
            \]})
call test_frame#Run()
