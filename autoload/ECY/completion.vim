fun! s:GetBufferID()
    if !exists('b:buffer_id')
      return -1
    endif
    return b:buffer_id
endf

fun! DoCompletion(context)
  if ECY#utility#GetCurrentBufferPath() != a:context['context']['params']['buffer_path'] 
        \|| s:GetBufferID() != a:context['context']['params']['buffer_id']
    return
  endif
  let l:show_list = a:context['show_list']

  if l:show_list == []
    return
  endif

  let l:show_windows = []
  for item in l:show_list
    let l:line = item['abbr']
    if has_key('kind', item)
      let l:line .= item['kind']
    endif
    call add(l:show_windows, l:line)
  endfor
  let g:abc = l:show_windows
endf
