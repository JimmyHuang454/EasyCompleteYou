" Author: Jimmy Huang (1902161621@qq.com)
" License: WTFPL

if !exists('g:loaded_clap')
  finish
endif

let s:ECY = {}

function! s:ECY.sink(selected) abort
  let l:splitted = split(a:selected, " ")
  let l:splitted = l:splitted[len(l:splitted) - 1]
  let l:res = g:ECY_qf_res[l:splitted]

  let l:action = ''
  if has_key(g:clap, 'open_action')
    let l:action = g:clap.open_action
  endif

  let l:Fuc = g:ECY_action_fuc['open#current_buffer']
  if l:action == 'tab split'
    let l:Fuc = g:ECY_action_fuc['open#new_tab']
  elseif l:action == 'vsplit'
    let l:Fuc = g:ECY_action_fuc['open#vertically']
  elseif l:action == 'split'
    let l:Fuc = g:ECY_action_fuc['open#horizontally']
  endif
  call l:Fuc(l:res)
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
let s:ECY.support_open_action = v:true
let s:ECY.action = {
      \ 'OpenInNew&Tab': { -> clap#selection#try_open('ctrl-t') },
      \ 'Open&Vertically': { -> clap#selection#try_open('ctrl-v') },
      \ }

let g:clap#provider#ECY# = s:ECY
