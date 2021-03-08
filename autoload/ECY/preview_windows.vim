" can only have one preview windows
function! ECY#preview_windows#Init() abort
"{{{ 
  let s:preview_windows_nr = -1
  " let g:ECY_enable_preview_snippet = get(g:,'ECY_enable_preview_snippet', v:true)

  let g:ECY_preview_windows_size = 
        \get(g:,'ECY_preview_windows_size',[[30, 70], [2, 14]])

  let i = g:ECY_preview_windows_size[0][1]
  let s:cut_line = ''
  while i != 0
    let s:cut_line .= '-'
    let i -= 1
  endw
  " TODO:
  " g:ECY_PreviewWindows_style = 'append'
  " g:ECY_PreviewWindows_style = 'preview_windows'
  let g:ECY_PreviewWindows_style = 
        \get(g:,'ECY_PreviewWindows_style','append')

  let g:ycm_autoclose_preview_window_after_completion
        \= get(g:,'ycm_autoclose_preview_window_after_completion',v:true)
"}}}
endfunction

function! ECY#preview_windows#Show(msg) abort
"{{{ won't be triggered when there are no floating windows features.
  if !ECY#completion#IsMenuOpen()
    return
  endif
  call ECY#preview_windows#Close()
  if g:has_floating_windows_support == 'vim'
    let l:highlight = ECY#utils#GetCurrentBufferFileType()
    let s:preview_windows_nr = s:PreviewWindows_vim(a:msg, l:highlight)
  else
    "TODO
    " let s:preview_windows_nr = s:PreviewWindows_neovim(a:msg, a:using_highlight)
  endif
"}}}
endfunction

function! ECY#preview_windows#Open() abort
"{{{ won't be triggered when there are no floating windows features.
  if g:has_floating_windows_support == 'vim'
    let l:selecting_item_nr = 
          \g:ECY_current_popup_windows_info['selecting_item']
    if l:selecting_item_nr != 0
      let l:item_info = 
            \g:ECY_current_popup_windows_info['items_info'][l:selecting_item_nr - 1]
      let l:highlight = ECY#utils#GetCurrentBufferFileType()
      let s:preview_windows_nr = s:PreviewWindows_vim(l:item_info, l:highlight)
    endif
  else
    "TODO
    " let s:preview_windows_nr = s:PreviewWindows_neovim(a:msg, a:using_highlight)
  endif
"}}}
endfunction

function! ECY#preview_windows#Close() abort
"{{{
  if g:has_floating_windows_support == 'vim'
    if s:preview_windows_nr != -1
      call popup_close(s:preview_windows_nr)
      let s:preview_windows_nr = -1
    endif
  elseif g:has_floating_windows_support == 'neovim'
    " TODO
  elseif g:has_floating_windows_support == 'has_no'
"{{{ old school
    if !g:ycm_autoclose_preview_window_after_completion
      return
    endif
    " this function was copied from ycm and the variable option is same as ycm.
    let l:current_buffer_name = bufname('')

    " We don't want to try to close the preview window in special buffers like
    " "[Command Line]"; if we do, Vim goes bonkers. Special buffers always start
    " with '['.
    if l:current_buffer_name[ 0 ] == '['
      return
    endif

    " This command does the actual closing of the preview window. If no preview
    " window is shown, nothing happens.
    pclose
"}}}
  endif
"}}}
endfunction

function s:PreviewWindows_neovim(items, using_highlight) abort
" TODO
endfunction

function s:PreviewWindows_vim(msg, using_highlight) abort
"{{{ return a floating_win_nr

  let l:to_show_list = []

  let l:item_menu = a:msg['menu']
  if type(l:item_menu) == v:t_string
    let l:item_menu = split(l:item_menu, "\n")
  endif
  if l:item_menu != []
    call extend(l:to_show_list, l:item_menu)
  endif

  let l:item_info = a:msg['info']
  if type(l:item_info) == v:t_string
    let l:item_info = split(l:item_info, "\n")
  endif
  if l:item_info != []
    call add(l:to_show_list, s:cut_line)
    call extend(l:to_show_list, l:item_info)
  endif

  if len(l:to_show_list) == 0
    return -1
  endif

  if g:ECY_PreviewWindows_style == 'append'
    if g:ECY_use_floating_windows_to_be_popup_windows == v:true
      let l:col = g:ECY_current_popup_windows_info['floating_windows_width'] 
            \+ g:ECY_current_popup_windows_info['opts']['col']
      let l:line = g:ECY_current_popup_windows_info['opts']['line']
    else
      " has floating windows, but user don't want to use it to be popup window
      let l:event = copy(v:event)
      let l:col  = l:event['col'] + l:event['width'] + 1
      let l:line = l:event['row'] + 1
    endif

    let l:opts = {
        \ 'minwidth': g:ECY_preview_windows_size[0][0],
        \ 'maxwidth': g:ECY_preview_windows_size[0][1],
        \ 'pos': 'topleft',
        \ 'col': l:col,
        \ 'line': l:line,
        \ 'minheight': g:ECY_preview_windows_size[1][0],
        \ 'maxheight': g:ECY_preview_windows_size[1][1],
        \ 'border': [],
        \ 'close': 'click',
        \ 'scrollbar': 1,
        \ 'firstline': 1,
        \ 'padding': [0,1,0,1],
        \ 'zindex': 2000}
  else
    " TODO:
    " waitting for vim to support more operation of floating windows
  endif

  let l:nr = popup_create(l:to_show_list,l:opts)
  call setbufvar(winbufnr(l:nr), '&syntax', a:using_highlight)
  return l:nr
"}}}
endfunction
