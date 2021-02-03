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

fun! DoCompletion_vim(context)
"{{{
  if ECY#utility#GetCurrentBufferPath() != a:context['params']['buffer_path'] 
        \|| GetBufferIDNotChange() != a:context['params']['buffer_id']
    return
  endif
  if s:popup_windows_nr != -1
    call CloseCompletionWindows()
  endif

  let l:fliter_words = a:context['filter_key']
  let l:items_info = a:context['show_list']

  let l:offset_of_cursor = len(l:fliter_words)
  let l:col  = 'cursor-' . l:offset_of_cursor
  let l:opts = {'pos': 'topleft',
        \'zindex':1000,
        \'line':'cursor+1',
        \'col': l:col}
  let l:to_show = []
  let l:to_show_matched_point = []
  let l:max_len_of_showing_item = 1
  for value in l:items_info
    let l:showing = value['abbr'].value['kind']
    call add(l:to_show, l:showing)
    call add(l:to_show_matched_point, value['match_point'])
    if len(l:showing) > l:max_len_of_showing_item
      let l:max_len_of_showing_item = len(l:showing)
    endif
  endfor

  let j = 0
  while j < len(l:to_show)
    let l:temp = l:max_len_of_showing_item - len(l:to_show[j])
    let i = 0
    while i < l:temp
      let l:to_show[j] .= ' '
      let i += 1
    endw
    let j += 1
  endw
  let s:popup_windows_nr = popup_atcursor(l:to_show, l:opts)
  let g:ECY_current_popup_windows_info = {'windows_nr': s:popup_windows_nr,
        \'selecting_item':0,'items_info':l:items_info,
        \'opts': popup_getoptions(s:popup_windows_nr)}
  " In vim, there are no API to get the floating windows' width, we calculate
  " it at here.
  " it must contain at least one item of list, so we set 0 at here.
  let g:ECY_current_popup_windows_info['floating_windows_width'] = 
        \l:max_len_of_showing_item

  let g:ECY_current_popup_windows_info['keyword_cache'] = l:fliter_words

  " hightlight it
  let i = 0
  while i < len(l:to_show_matched_point)
    let j = 0
    let l:point = l:to_show_matched_point[i]
    while j < len(l:to_show[i])
      if ECY#utility#IsInList(j, l:point)
        let l:hightlight = 'ECY_floating_windows_normal_matched'
      else
        let l:hightlight = 'ECY_floating_windows_normal'
      endif
      let l:line  = i + 1
      let l:start = j + 1
      let l:exe = "call prop_add(".l:line.",".l:start.", {'length':1,'type': '".l:hightlight."'})"
      call win_execute(s:popup_windows_nr, l:exe)
      let j += 1
    endw
    let i += 1
  endw

  return s:popup_windows_nr
"}}}
endf

fun! DoCompletion(context)
"{{{
  if g:has_floating_windows_support == 'vim'
    call DoCompletion_vim(a:context)
  elseif g:has_floating_windows_support == 'neovim'
  else " has no
  endif
"}}}
endf

function! CloseCompletionWindows() abort
  if g:has_floating_windows_support == 'vim'
    call popup_close(s:popup_windows_nr)
    let s:popup_windows_nr = -1
  else
    "TODO: neovim
  endif
endfunction

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

  let s:popup_windows_nr = -1
  call DefineColor('ECY_floating_windows_normal_matched', 'guifg=#945596	guibg=#073642	ctermfg=red	  ctermbg=darkBlue')
  call DefineColor('ECY_floating_windows_normal', 'guifg=#839496	guibg=#073642	ctermfg=white	ctermbg=darkBlue')
  call DefineColor('ECY_floating_windows_seleted_matched', 'guifg=#FFFF99	guibg=#586e75	ctermfg=red	ctermbg=Blue')
  call DefineColor('ECY_floating_windows_seleted', 'guifg=#eee8d5	guibg=#586e75	ctermfg=white	ctermbg=Blue')
"}}}
endf




call s:Init()
