fun! ECY#hover#Init() abort
  
endf

fun! ECY#hover#Open(msg) abort
  if mode() != 'n'
    return
  endif
 let opts = {"close":"button", "title":"Vim Messages", 'syntax': &syn}
 call quickui#textbox#open(a:msg, opts)
endf
