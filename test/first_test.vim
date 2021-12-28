let s:suite = themis#suite('Test for ECY')
let s:assert = themis#helper('assert')



function! AddLine(str)
    put! =a:str
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                                  content                                   "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function s:suite.test_default_engine_ok()
  " exe "so " . g:repo_root .'/test/test_frame.vim'
  " call AddLine("abc\nabcd\nabc")
  " call cursor(3, 3)

  " let s:abc = 1

  " call s:assert.equals(mode(), 'n')
  " call feedkeys('ier', 'in')

  " call s:assert.equals(ECY#utils#GetCurrentBufferFileType(), 'nothing')
  " let &ft="python"
  " call s:assert.equals(ECY#utils#GetCurrentBufferFileType(), 'python')
endfunction


function s:suite.my_test_2()
  " call s:assert.equals(s:abc, 1)
  " call s:assert.equals(mode(), 'n')
  call s:assert.equals(ECY#utils#GetCurrentBufferFileType(), 'nothing')
endfunction
