fun! GetBufferIDNotChange()
"{{{
    if !exists('b:buffer_id')
      return -1
    endif
    return b:buffer_id
"}}}
endf

fun! s:Indent(show_list)
"{{{
  let l:max = 0
  for item in a:show_list
    let l:lens = len(item['abbr'])
    if  l:lens> l:max
      let l:max = l:lens
    endif
  endfor
  let l:max += 2
  for item in a:show_list
    let l:lens = l:max - len(item['abbr'])
    let i = 0
    while i < l:lens
      let item['abbr'] = item['abbr'] . ' '
      let i += 1
    endw
  endfor
  return a:show_list
"}}}
endf

fun! DoCompletion(context)
"{{{
  if ECY#utility#GetCurrentBufferPath() != a:context['context']['params']['buffer_path'] 
        \|| GetBufferIDNotChange() != a:context['context']['params']['buffer_id']
    return
  endif
  if a:context['show_list'] == []
    return
  endif

  " let l:show_list = s:Indent(a:context['show_list'])
  let l:show_list = a:context['show_list']

  let l:show_windows = []
  for item in l:show_list
    let l:line = item['abbr']
    if has_key(item, 'kind')
      let l:line .= item['kind']
    endif 
    call add(l:show_windows, l:line)
  endfor
  let g:abc = l:show_windows
  call popup_atcursor(l:show_windows, {})
"}}}
endf

fun! s:Init()
"{{{
  if has('nvim') && exists('*nvim_win_set_config')
    let g:has_floating_windows_support = 'nvim'
    " TODO:
    let g:has_floating_windows_support = 'has_no'
  elseif has('textprop') && has('popupwin')
    let g:has_floating_windows_support = 'vim'
  else
    let g:has_floating_windows_support = 'has_no'
  endif
"}}}
endf


call s:Init()
