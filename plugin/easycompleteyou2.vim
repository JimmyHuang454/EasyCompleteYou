" This is basic vim plugin boilerplate
let s:save_cpo = &cpo
set cpo&vim

let g:ECY_starttime = reltimefloat(reltime())
let g:loaded_ECY2 = v:false

function! s:restore_cpo()
  let g:loaded_ECY2 = v:true
  let &cpo = s:save_cpo
  unlet s:save_cpo
endfunction

let g:is_vim = !has('nvim')

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                                check require                                "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
if g:loaded_ECY2
  finish
elseif v:version < 800
  echohl WarningMsg |
        \ echomsg "ECY unavailable: requires Vim 8.0+." |
        \ echohl None
  call s:restore_cpo()
  finish
elseif &encoding !~? 'utf-\?8'
  echohl WarningMsg |
        \ echomsg "ECY unavailable: requires UTF-8 encoding. " .
        \ "Put the line 'set encoding=utf-8' in your vimrc." |
        \ echohl None
  call s:restore_cpo()
  finish
elseif !has('python3')
  echohl WarningMsg |
        \ echomsg "ECY unavailable: unable to load Python3." |
        \ echohl None
  call s:restore_cpo()
  finish
elseif ( g:is_vim && (!exists('*job_start') || !has('channel')) ) || 
      \ (!g:is_vim && !has('nvim-0.2.0'))
  echohl WarningMsg |
        \ echomsg "ECY unavailable: requires NeoVim >= 0.2.0 ".
        \ "or Vim 8 with +job +channel." |
        \ echohl None
  call s:restore_cpo()
  finish
elseif !exists( '*json_decode' )
  echohl WarningMsg |
        \ echomsg "ECY unavailable: requires with function of json_decode. ".
        \ "You should build Vim with this feature." |
        \ echohl None
  call s:restore_cpo()
  finish
endif

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                                 init vars                                  "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
if g:is_vim && exists('*nvim_win_set_config') " neovim
  " TODO:
  let g:has_floating_windows_support = 'neovim'
  let g:has_floating_windows_support = 'has_no' 

elseif has('textprop') && has('popupwin')
  let g:has_floating_windows_support = 'vim'
else
  let g:has_floating_windows_support = 'has_no'
  let g:ECY_use_floating_windows_to_be_popup_windows = v:false
endif
" let g:ECY_use_floating_windows_to_be_popup_windows = v:false

" must put these outside a function
let g:ECY_base_dir = expand( '<sfile>:p:h:h' )
let g:ECY_base_dir = tr(g:ECY_base_dir, '\', '/')
let g:ECY_buffer_version = {}

let g:ECY_python_script_folder_path = g:ECY_base_dir . '/python'

if exists('g:ycm_disable_for_files_larger_than_kb')
  let g:ECY_disable_for_files_larger_than_kb = g:ycm_disable_for_files_larger_than_kb
else
  let g:ECY_disable_for_files_larger_than_kb
        \= get(g:,'ECY_disable_for_files_larger_than_kb', 1024)
endif

let g:ECY_file_type_blacklist
      \= get(g:,'ECY_file_type_blacklist', ['log'])


""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                                     Go                                     "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
call ECY#completion#Init()
call ECY#preview_windows#Init()
call ECY#switch_engine#Init()
call ECY2_main#Init()

let g:ECY_endtime = reltimefloat(reltime())
let g:ECY_start_time = g:ECY_endtime - g:ECY_starttime
call s:restore_cpo()
