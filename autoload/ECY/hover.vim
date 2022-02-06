fun! ECY#hover#Init() abort
  
endf

fun! ECY#hover#Open(msg) abort
  if mode() != 'n'
    return
  endif

 let s:popup_obj = easy_windows#new()
 let l:temp = s:popup_obj._open(a:msg, {
       \'at_cursor': 1,
       \'use_border': 1,
       \'syntax': &ft,
       \'x': easy_windows#get_cursor_screen_x(),
       \'y': easy_windows#get_cursor_screen_y() + 1})
  call s:popup_obj._align_width()
  call s:popup_obj._align_height()
endf
