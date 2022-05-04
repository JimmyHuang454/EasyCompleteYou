" Author: Jimmy Huang (1902161621@qq.com)
" License: WTFPL

if !exists('g:leaderf_loaded') || leaderf#versionCheck() == 0
  finish
endif

let s:extension = {
            \   "name": "ECY",
            \   "help": "check out Doc of ECY",
            \   "registerFunc": "g:LeaderfECY_Register",
            \   "arguments": [
            \   ]
            \ }
call g:LfRegisterPythonExtension(s:extension['name'], s:extension)

exec g:Lf_py "import vim, sys, os.path"
exec g:Lf_py "cwd = vim.eval('expand(\"<sfile>:p:h\")')"
exec g:Lf_py "sys.path.insert(0, cwd)"
exec g:Lf_py "from leaderf_python.selecting import *"

function! g:LeaderfECY_Register(name)
"{{{
exec g:Lf_py "<< EOF"
from leaderf.anyExpl import anyHub
anyHub.addPythonExtension(vim.eval("a:name"), ECY_leaderf_selecting)
EOF
"}}}
endfunction

function! g:LeaderfECY_Maps()
"{{{
    nmapclear <buffer>
    nnoremap <buffer> <silent> <CR>          :exec g:Lf_py "ECY_leaderf_selecting.accept()"<CR>
    nnoremap <buffer> <silent> o             :exec g:Lf_py "ECY_leaderf_selecting.accept()"<CR>
    nnoremap <buffer> <silent> <2-LeftMouse> :exec g:Lf_py "ECY_leaderf_selecting.accept()"<CR>
    nnoremap <buffer> <silent> x             :exec g:Lf_py "ECY_leaderf_selecting.accept('h')"<CR>
    nnoremap <buffer> <silent> s             :exec g:Lf_py "ECY_leaderf_selecting.accept('v')"<CR>
    nnoremap <buffer> <silent> t             :exec g:Lf_py "ECY_leaderf_selecting.accept('t')"<CR>
    nnoremap <buffer> <silent> p             :exec g:Lf_py "ECY_leaderf_selecting._previewResult(True)"<CR>
    nnoremap <buffer> <silent> q             :exec g:Lf_py "ECY_leaderf_selecting.quit()"<CR>
    nnoremap <buffer> <silent> i             :exec g:Lf_py "ECY_leaderf_selecting.input()"<CR>
    nnoremap <buffer> <silent> <F1>          :exec g:Lf_py "ECY_leaderf_selecting.toggleHelp()"<CR>
    if has_key(g:Lf_NormalMap, "Marks")
        for i in g:Lf_NormalMap["Marks"]
            exec 'nnoremap <buffer> <silent> '.i[0].' '.i[1]
        endfor
    endif
"}}}
endfunction

function! g:LeaderfECY_Start()
    " the ECY_leaderf_selecting is from "~/plugin/leaderf_python/selecting.py"
  call leaderf#LfPy(printf("ECY_leaderf_selecting.startExplorer('%s')", g:Lf_WindowPosition))
endfunction

function! g:LeaderfECY_Event(line, event, index, modes) abort
"{{{ call by python of leaderf
  let l:res = {}
  if a:index >= 0
    let l:res = g:ECY_qf_res[a:index]
  endif

  let g:abc1 = a:modes

  let l:Fuc = g:ECY_action_fuc['open#current_buffer']
  if a:modes == 't'
    let l:Fuc = g:ECY_action_fuc['open#new_tab']
  elseif a:modes == 'v'
    let l:Fuc = g:ECY_action_fuc['open#vertically']
  elseif a:modes == 'h'
    let l:Fuc = g:ECY_action_fuc['open#horizontally']
  endif

  call l:Fuc(l:res)
"}}}
endfunction
