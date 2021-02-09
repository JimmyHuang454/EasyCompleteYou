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

  if len(l:items_info) == 0
    return
  endif

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
  let s:popup_windows_nr = popup_create(l:to_show, l:opts)
  let g:ECY_current_popup_windows_info = {'windows_nr': s:popup_windows_nr,
        \'selecting_item':0,
        \'start_position': a:context['start_position'],
        \'items_info': l:items_info,
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
  if (g:popup_windows_is_selecting || len(a:context['filter_key']) <= g:ECY_triggering_length) 
        \&& !a:context['must_show']
    return
  endif

  if g:has_floating_windows_support == 'vim'
    call DoCompletion_vim(a:context)
  elseif g:has_floating_windows_support == 'neovim'
  else " has no
  endif
"}}}
endf

function! CloseCompletionWindows() abort
"{{{
  if g:popup_windows_is_selecting
    return
  endif
  if g:has_floating_windows_support == 'vim'
    try
      call popup_close(s:popup_windows_nr)
    catch 
    endtry
    let s:popup_windows_nr = -1
  else
    "TODO: neovim
  endif
"}}}
endfunction

function! IsMenuOpen() abort
"{{{
  if g:has_floating_windows_support == 'vim'
    if g:ECY_use_floating_windows_to_be_popup_windows == v:false
      return pumvisible()
    endif
    if s:popup_windows_nr != -1
      return v:true
    endif
    return v:false
  elseif g:has_floating_windows_support == 'has_no'
    return pumvisible()
  endif
"}}}
endfunction

function! Complete(position, words) abort
"{{{
   let l:current_colum = (col('.') - 1)
   let l:complete_col = a:position['colum']
   let l:gap = l:current_colum - l:complete_col
   if l:gap == 0
     return
   endif
   let l:current_line = getline(".")
   let l:new_line = l:current_line[: l:complete_col - 1] . a:words . l:current_line[l:complete_col + l:gap:]
   call setline(line('.'), l:new_line)
   return l:new_line
"}}}
endfunction

function! SelectItems_vim(next_or_pre) abort
"{{{
  if a:next_or_pre == 0
    let l:round = 1
  else
    let l:round = -1
  endif
  let l:start_colum = g:ECY_current_popup_windows_info['start_position']['colum']
  " call Complete(g:ECY_current_popup_windows_info['start_position'], 'sdf')

  " loop
  let l:items_info       = g:ECY_current_popup_windows_info['items_info']
  let l:current_item     = g:ECY_current_popup_windows_info['selecting_item']
  let l:showing_item_len = len(l:items_info)
  let l:next_item        = (l:current_item + l:round) % (l:showing_item_len + 1)
  if l:next_item == -1
    let l:next_item = l:showing_item_len
  endif
  let g:ECY_current_popup_windows_info['selecting_item'] = l:next_item

  " call complete(l:start_colum + 1, ['sdf'])
  " return
  " complete and hightlight the new one 
  " let l:exe = "call prop_remove({'type':'item_selected','all':v:true})"
  " call win_execute(s:popup_windows_nr, l:exe)
  if l:next_item == 0
    let l:to_complete =  g:ECY_current_popup_windows_info['keyword_cache']
    " don't need to hightlight at here
  else
    let l:to_complete =  l:items_info[l:next_item - 1]['word']

    let l:exe = "call prop_clear(". l:next_item .")"
    call win_execute(s:popup_windows_nr, l:exe)
    let l:info = l:items_info[l:next_item-1]
    let l:temp = len(l:info['abbr'].l:info['kind'])
    let l:point = l:info['match_point']
    let i = 0
    while i < g:ECY_current_popup_windows_info['floating_windows_width']
      if ECY#utility#IsInList(i, l:point)
        let l:hightlight = 'ECY_floating_windows_seleted_matched'
      else
        let l:hightlight = 'ECY_floating_windows_seleted'
      endif
      if l:temp > i
        let l:start = i + 1
        let l:length = 1
      else
        let l:length = 100
      endif
      let l:exe = "call prop_add(".l:next_item.",".l:start.", {'length':".l:length.",'type': '".l:hightlight."'})"
      call win_execute(s:popup_windows_nr, l:exe)
      let i += 1
    endw
  endif

  " unhighlight the old one.
  if l:current_item != 0
    let l:exe = "call prop_clear(". l:current_item .")"
    call win_execute(s:popup_windows_nr, l:exe)
    let l:info = l:items_info[l:current_item-1]
    let l:temp = len(l:info['abbr'].l:info['kind'])
    let l:point = l:info['match_point']
    let i = 0
    while i < g:ECY_current_popup_windows_info['floating_windows_width']
      if ECY#utility#IsInList(i, l:point)
        let l:hightlight = 'ECY_floating_windows_normal_matched'
      else
        let l:hightlight = 'ECY_floating_windows_normal'
      endif
      if l:temp > i
        let l:start = i + 1
        let l:length = 1
      else
        let l:length = 100
      endif
      let l:exe = "call prop_add(".l:current_item.",".l:start.", {'length':".l:length.",'type': '".l:hightlight."'})"
      call win_execute(s:popup_windows_nr, l:exe)
      let i += 1
    endw
  endif

  " this function will trigger the insert event, and we don't want it to 
  " be triggered while completing.
  " IMPORTANCE: when comment this function, vim will not highlight the
  " selected item, because we filter the key of <Tab> that is selecting
  " mapping, then the s:isSelecting in ECY_main.vim can not be reset.
  call complete(l:start_colum+1,[l:to_complete])

"}}}
endfunction

function! SelectItems(next_or_prev, send_key) abort
"{{{
  if !IsMenuOpen()
    call ECY#utility#SendKeys(a:send_key)
  else
    let g:popup_windows_is_selecting = v:true
    call SelectItems_vim(a:next_or_prev)
  endif
  return ''
"}}}
endfunction

fun! s:Init()
"{{{
  let g:ECY_use_floating_windows_to_be_popup_windows = 
        \get(g:, 'ECY_use_floating_windows_to_be_popup_windows', v:true)

  let g:ECY_select_items
        \= get(g:, 'ECY_select_items',['h','<S-TAB>'])

  let g:ECY_triggering_length
        \= get(g:,'ECY_triggering_length',1)

  " let g:ECY_select_items = ['h','<S-TAB>']

  let s:popup_windows_nr = -1
  let g:popup_windows_is_selecting = v:false
  call DefineColor('ECY_floating_windows_normal_matched', 'guifg=#945596	guibg=#073642	ctermfg=red	  ctermbg=darkBlue')
  call DefineColor('ECY_floating_windows_normal', 'guifg=#839496	guibg=#073642	ctermfg=white	ctermbg=darkBlue')
  call DefineColor('ECY_floating_windows_seleted_matched', 'guifg=#FFFF99	guibg=#586e75	ctermfg=red	ctermbg=Blue')
  call DefineColor('ECY_floating_windows_seleted', 'guifg=#eee8d5	guibg=#586e75	ctermfg=white	ctermbg=Blue')

  augroup ECY_completion
    autocmd!
    autocmd TextChangedI  * call CloseCompletionWindows()
    autocmd InsertLeave   * call CloseCompletionWindows()
  augroup END

  if g:ECY_use_floating_windows_to_be_popup_windows == v:false
    exe 'inoremap <expr>' . g:ECY_select_items[0] .
          \ ' pumvisible() ? "\<C-n>" : "\' . g:ECY_select_items[0] .'"'
    exe 'inoremap <expr>' . g:ECY_select_items[1] .
          \ ' pumvisible() ? "\<C-p>" : "\' . g:ECY_select_items[1] .'"'
  else
    exe 'inoremap <silent> ' . g:ECY_select_items[0].' <C-R>=SelectItems(0,"\' . g:ECY_select_items[0] . '")<CR>'
    exe 'inoremap <silent> ' . g:ECY_select_items[1].' <C-R>=SelectItems(1,"\' . g:ECY_select_items[1] . '")<CR>'
  endif
"}}}
endf

call s:Init()
