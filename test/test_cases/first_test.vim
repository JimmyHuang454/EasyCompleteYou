let g:repo_root = fnamemodify(expand('<sfile>'), ':h:h:h')
let g:log_file = expand('<sfile>') . '.log'
exe printf('so %s/test/startup.vim', g:repo_root)


function! s:T1() abort
    new
    call Expect(ECY#utils#GetCurrentBufferFileType(), 'nothing')
    let &ft = 'python'
    call Expect(&ft, 'python')
    call Expect(ECY#utils#GetCurrentBufferFileType(), 'python')
    call Expect(ECY#switch_engine#GetBufferEngineName(), 'ECY.engines.default_engine')
endfunction

call test_frame#Add({'event':[{'fuc': function('s:T1')}]})
call test_frame#Run()
