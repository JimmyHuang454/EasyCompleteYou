fun! ECY#code_lens#Init() abort
"{{{
  let g:ECY_enable_code_lens = 
        \get(g:, 'ECY_enable_code_lens', v:true)

  let g:ECY_disable_code_lens_in_insert_mode = 
        \get(g:, 'ECY_disable_code_lens_in_insert_mode', v:true)

  let g:ECY_code_lens_info = {}
"}}}
endf

fun! s:RenderBuffer() abort
"{{{
  if !g:ECY_enable_code_lens
    return
  endif

  let l:buffer_path = ECY#utils#GetCurrentBufferPath()

  if !has_key(g:ECY_code_lens_info, l:buffer_path) || !ECY2_main#IsWorkAtCurrentBuffer()
    return
  endif

"}}}
endf

fun! ECY#code_lens#Do(context) abort
"{{{
  let l:path = a:context['path']
  let g:ECY_code_lens_info[l:path] = a:context
  call s:RenderBuffer()
"}}}
endf
