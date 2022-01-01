let g:repo_root = fnamemodify(expand('<sfile>'), ':h:h:h')
let g:log_file = expand('<sfile>') . '.log'
exe printf('so %s/test/startup.vim', g:repo_root)


function! s:T1() abort
    new
    call Expect(ECY#utils#GetCurrentBufferFileType(), 'nothing')
    let &ft = 'test'
    call Expect(&ft, 'test')
    call Expect(ECY#utils#GetCurrentBufferFileType(), 'test')
    call Expect(mode(), 'n')
    call Type("i123\n12")
endfunction

function! s:T2() abort
    call OutputLine(string(g:ECY_start_time))
    call Expect(exists('g:ECY_start_time'), 1)
    call Expect(getline(1), '123')
    call Type("\<Esc>")
endfunction

function! s:T3() abort
    call Type("a")
endfunction

function! s:T4() abort
    call Type("\<Tab>")
endfunction

function! s:T5() abort
    call Expect(getline(2), '123')
endfunction

call test_frame#Add({'event':[{'fuc': function('s:T1')}, 
            \{'fuc': function('s:T2')}, 
            \{'fuc': function('s:T3')},
            \{'fuc': function('s:T4')},
            \{'fuc': function('s:T5')},
            \]})
call test_frame#Run()
