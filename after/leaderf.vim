" Author: Jimmy Huang (1902161621@qq.com)
" License: WTFPL

function! s:SetUpLeaderf() abort
"{{{
  " In order to be listed by :LeaderfSelf
  call g:LfRegisterSelf("ECY_selecting", "Plugin for EasyCompleteYou")

  " In order to make this plugin in Leaderf available 
  let s:extension = {
              \   "name": "ECY_selecting",
              \   "help": "check out Doc of ECY",
              \   "registerFunc": "ECY#leaderf#main#register",
              \   "arguments": [
              \   ]
              \ }
  call g:LfRegisterPythonExtension(s:extension.name, s:extension)
"}}}
endfunction

try
  if g:loaded_easycomplete
    call s:SetUpLeaderf()
  endif
catch 
  " call ECY#utils#echo("[ECY] You have no Leaderf.")
endtry
