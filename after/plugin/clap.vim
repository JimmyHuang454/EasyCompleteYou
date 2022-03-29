" Author: Jimmy Huang (1902161621@qq.com)
" License: WTFPL

if !exists('g:loaded_clap')
  finish
endif

let s:ECY = {}

function! s:ECY.sink(selected) abort
  let l:splitted = split(a:selected, " ")
  let l:splitted = l:splitted[len(l:splitted) - 1]
  call g:ECY_qf_key_map["<cr>"](l:splitted)
endfunction


function! s:ECY.source() abort
  let l:res = []
  let i = 0
  for item in g:ECY_qf_res
    call add(l:res, printf("%s %s", item['abbr'], string(i)))
    let i += 1
  endfor
  return l:res
endfunction

let s:ECY.syntax = 'clap_lines'
let g:clap#provider#ECY# = s:ECY
