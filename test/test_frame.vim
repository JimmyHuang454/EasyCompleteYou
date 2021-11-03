fun! test_frame#Init()
  let s:is_input_working = v:false
  let g:ECY_testing_case = []
  let s:testing_case_nr = 0
  let s:testing_case_event = 0
  let s:testing_windows_nr = -1
endf

fun! test_frame#Add(test_case) abort
  call add(g:ECY_testing_case, a:test_case)
endf

fun! s:Start(timer) abort
"{{{
  let l:item = g:ECY_testing_case[s:testing_case_nr]['event'][s:testing_case_event]
  echo ' event: '. string(l:item)
  let l:Fuc = l:item['fuc']
  call l:Fuc()

  let s:testing_case_event += 1
  if s:testing_case_event == len(g:ECY_testing_case[s:testing_case_nr]['event'])
    let s:testing_case_event = 0
    if s:testing_case_nr == len(g:ECY_testing_case[s:testing_case_nr]) - 1
      " all test ended.
      return 
    endif
    let s:testing_case_nr += 1
  endif
  call timer_start(1000, function('s:Start'))
"}}}
endf

fun! RunTest() abort
  call s:Start(1)
endf

function! AddLine(str)
    put! =a:str
endfunction

call test_frame#Init()
call RunTest()
