
fun! ECY#selete#Do(res) abort
  if !exists('g:loaded_CtrlT')
    call ECY#utils#echo("Need 'CtrlT'")
    return
  endif
  let g:CtrlT_ECY_list = a:res
  exe "CtrlT ECY_symbol"
endf
