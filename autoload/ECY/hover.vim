fun! ECY#hover#Init() abort
  
endf

fun! ECY#hover#Open(msg) abort
  if mode() != 'n'
    return
  endif
  if g:has_floating_windows_support == 'vim'
    let l:nr = popup_atcursor(a:msg, {
      \ 'border': [],
      \ 'minwidth': g:ECY_preview_windows_size[0][0],
      \ 'maxwidth': g:ECY_preview_windows_size[0][1],
      \ 'minheight': g:ECY_preview_windows_size[1][0],
      \ 'maxheight': g:ECY_preview_windows_size[1][1],
      \ 'close': 'click',
      \ 'borderchars': ['-', '|', '-', '|', '┌', '┐', '┘', '└']
      \})
     call setbufvar(winbufnr(l:nr), '&syntax', &syn)
  endif
endf
