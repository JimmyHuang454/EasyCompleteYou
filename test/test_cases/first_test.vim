let g:repo_root = fnamemodify(expand('<sfile>'), ':h:h:h')
let g:log_file = expand('<sfile>') . '.log'
exe printf('so %s/test/startup.vim', g:repo_root)


function! s:T1() abort
    new
    call Expect(ECY#utils#GetCurrentBufferFileType(), 'nothing')
    let &ft = 'python'
    call Expect(&ft, 'python')
    call Expect(ECY#utils#GetCurrentBufferFileType(), 'python')
    call Expect(mode(), 'n')
    call feedkeys("i123\n12", 'in')
    call Expect(getline(1), '123')
endfunction

function! s:T2() abort
    call feedkeys("\<Esc>", 'in')
endfunction

function! s:T3() abort
    call feedkeys("a", 'in')
endfunction

function! s:T4() abort
    call feedkeys("\<Tab>", 'in')
    call Expect(getline(2), '123')
endfunction

call test_frame#Add({'event':[{'fuc': function('s:T1')}, 
            \{'fuc': function('s:T2')}, 
            \{'fuc': function('s:T3')},
            \{'fuc': function('s:T4')},
            \]})
call test_frame#Run()
