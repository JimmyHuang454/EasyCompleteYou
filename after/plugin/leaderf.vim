" Author: Jimmy Huang (1902161621@qq.com)
" License: WTFPL

if !exists('g:leaderf_loaded')
  finish
endif

function! LfSpellSink(line,...)
  exe 'normal! "_ciw'.a:line
endfunction

function! LfSpell(args)
  return spellsuggest(expand(get(a:args, "pattern",[""])[0]))
endfunction

let g:Lf_Extensions = {
    \ "spell": {
    \       "source": "LfSpell",
    \       "arguments" : [
    \       {"name":["pattern"], "nargs":1 },
    \       ],
    \       "accept": "LfSpellSink",
    \ }
    \} 
