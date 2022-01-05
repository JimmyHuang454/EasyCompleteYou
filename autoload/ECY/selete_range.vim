fun! ECY#selete_range#Init() abort
"{{{
  let s:origin_res = {}
  let s:level = 1
"}}}
endf

fun! ECY#selete_range#Do(origin_res) abort " new
"{{{
  let s:origin_res = a:origin_res
  let s:level = 0 " the root.
  let l:res = s:Into(s:level)
"}}}
endf

fun! s:Into(level) abort " and selete with selete mode.
"{{{
  let i = 0
  let l:temp = s:origin_res
  while i < a:level
    if !has_key(l:temp, 'parent')
      let l:temp['topest'] = 1
      break
    endif
    let l:temp = l:temp['parent']
    let i += 1
  endw

  let l:start = l:temp['range']['start']
  let l:end = l:temp['range']['end']

  call ECY#utils#SeleteRange(
        \[l:start['line'] + 1, l:start['character'] + 1],
        \[l:end['line'] + 1, l:end['character'] + 1], bufnr(''))
  return l:temp
"}}}
endf

fun! ECY#selete_range#Parent() abort
"{{{
  let l:res =  s:Into(s:level + 1)
  if !has_key(l:res, 'topest')
    let s:level += 1
  endif
"}}}
endf

fun! ECY#selete_range#Child() abort
"{{{
  if s:level != 0
    let s:level -= 1
  endif
  call s:Into(s:level)
"}}}
endf
