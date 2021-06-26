
fun! ECY#selete#Do(context) abort
  if !exists('g:loaded_CtrlT')
    return
  endif
  call CtrlT#engines#ECY#Do(a:context)
endf
