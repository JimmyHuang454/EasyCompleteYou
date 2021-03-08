" This is basic vim plugin boilerplate
let s:save_cpo = &cpo
set cpo&vim

let g:ECY_starttime = reltimefloat(reltime())

function! s:restore_cpo()
  let g:loaded_ECY2 = v:true
  let &cpo = s:save_cpo
  unlet s:save_cpo
endfunction

let g:is_vim = !has('nvim')

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                                check require                                "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
if exists('g:loaded_ECY2')
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
        \ "Put the line 'set encoding=utf-8' into your vimrc." |
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

if executable('python3')
  let g:ECY_python_cmd = get(g:,'ECY_python_cmd', 'python3')
elseif executable('python')
  let g:ECY_is_debug = get(g:,'ECY_is_debug', v:false)
elseif !exists('g:ECY_is_debug')
  echohl WarningMsg |
        \ echomsg "ECY unavailable: Unkonw Python3 executable path".
        \ "You can set 'g:ECY_is_debug' to determine it." |
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
let g:ECY_windows_are_showing = {}

let g:ECY_python_script_folder_path = g:ECY_base_dir . '/python'

if exists('g:ycm_disable_for_files_larger_than_kb')
  let g:ECY_disable_for_files_larger_than_kb = g:ycm_disable_for_files_larger_than_kb
else
  let g:ECY_disable_for_files_larger_than_kb
        \= get(g:,'ECY_disable_for_files_larger_than_kb', 1024)
endif

let g:ECY_file_type_blacklist
      \= get(g:,'ECY_file_type_blacklist', ['log'])


vmap <C-h> <ESC>:call ECY2_main#DoCodeAction({'range_type': 'selected_range'})<CR>
nmap <C-h> :call ECY2_main#DoCodeAction({'range_type': 'current_line'})<CR>

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                                     Go                                     "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
call ECY#completion#Init()
call ECY#completion#Init()
call ECY#signature_help#Init()
call ECY#goto#Init()
call ECY#preview_windows#Init()
call ECY#switch_engine#Init()
call ECY#diagnostics#Init()
call ECY2_main#Init()

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"                                    end                                     "
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let g:ECY_endtime = reltimefloat(reltime())
let g:ECY_start_time = g:ECY_endtime - g:ECY_starttime

call s:restore_cpo()
