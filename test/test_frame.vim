fun! test_frame#Init()
  let s:is_input_working = v:false
  let g:ECY_testing_case = []
  let s:testing_case_nr = 0
  let s:testing_case_event = 0
  let s:testing_windows_nr = -1
endf

fun! g:TestFrameAdd(test_case) abort
  call add(g:ECY_testing_case, a:test_case)
endf

fun! TestFrameError(error_msg) abort
  call themis#log("completion not working.")
endf

fun! TestFrameGot(output) abort
  call themis#log(printf("Got: '%s'", a:output))
endf

fun! s:QuitVim() abort
  cquit!
endf

fun! s:Start(timer) abort
"{{{
  let l:item = g:ECY_testing_case[s:testing_case_nr]['event'][s:testing_case_event]
  call themis#log(' event: ' . string(l:item))
  let l:Fuc = l:item['fuc']

  try
    call l:Fuc()
  catch 
    call themis#log(v:exception)
    call themis#log(v:throwpoint)
    call s:QuitVim()
  endtry

  let s:testing_case_event += 1
  if s:testing_case_event == len(g:ECY_testing_case[s:testing_case_nr]['event'])
    let s:testing_case_event = 0
    if s:testing_case_nr == len(g:ECY_testing_case[s:testing_case_nr]) - 1
      " all test ended.
      call s:QuitVim()
    endif
    let s:testing_case_nr += 1
  endif
  call timer_start(1000, function('s:Start'))
"}}}
endf

fun! RunTest() abort
  exe "so " . g:repo_root .'/test/feedkey_test.vim'
  call timer_start(100, function('s:Start'))
endf

function! AddLine(str)
    put! =a:str
endfunction

call themis#log('starting...')
call test_frame#Init()
call RunTest()
