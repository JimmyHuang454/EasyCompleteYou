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

" must put these outside a function
let g:ECY_base_dir = expand( '<sfile>:p:h:h' )
let g:ECY_base_dir = tr(g:ECY_base_dir, '\', '/')
let g:ECY_buffer_version = {}

let g:ECY_python_script_folder_path = g:ECY_base_dir . '/python'
