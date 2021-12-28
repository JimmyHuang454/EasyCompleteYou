fun! s:T1() abort
"{{{
  new 
  call feedkeys("i123\n1234\n12345\n12", 'in')
"}}}
endf

fun! s:T2() abort
"{{{
  call feedkeys("\<tab>", 'i')
"}}}
endf

fun! s:T3() abort
"{{{
  if getline(4) != '123'
    call TestFrameGot(getline(4))
    throw "completion not working."
  endif
  call feedkeys("\<ctrl-n>", 'i')
  call feedkeys("\<Esc>", 'i')
"}}}
endf

call TestFrameAdd({'event':[{'fuc': function('s:T1')}, {'fuc': function('s:T2')},{'fuc': function('s:T3')}]})
