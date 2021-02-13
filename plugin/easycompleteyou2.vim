let g:is_vim = !has('nvim')

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
