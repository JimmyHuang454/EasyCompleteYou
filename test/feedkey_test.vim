fun! feedkey_test#T1() abort
"{{{
  new 
  call feedkeys("i123\n1234\n12345\n12", 'in')
"}}}
endf

fun! feedkey_test#T2() abort
"{{{
  call feedkeys("\<tab>", 'i')
"}}}
endf

fun! feedkey_test#T3() abort
"{{{
  if getline(4) != '123'
    call TestFrameGot(getline(4))
    throw "completion not working."
  endif
  call feedkeys("\<ctrl-n>", 'i')
  call feedkeys("\<Esc>", 'i')
"}}}
endf
