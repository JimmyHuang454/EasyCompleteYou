let g:repo_root = fnamemodify(expand('<sfile>'), ':h:h:h')
let g:log_file = expand('<sfile>') . '.log'
exe printf('so %s/test/startup.vim', g:repo_root)


function! s:T2() abort
    call Expect(ECY#utils#GetCurrentBufferFileType(), 'nothing')
endfunction

call test_frame#Add({'event':[{'fuc': function('s:T2')}]})
call test_frame#Run()
