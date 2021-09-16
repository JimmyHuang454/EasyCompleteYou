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

fun! s:DoCompletion_vim(context)
"{{{
  if s:popup_windows_nr != -1
    call ECY#completion#Close()
  endif

  let l:fliter_words = a:context['filter_key']
  let l:items_info = a:context['show_list']

  if len(l:items_info) == 0
    return
  endif

  let l:col = len(a:context['prev_key']) - len(l:fliter_words)
  let s:show_item_position = a:context['start_position']
  let s:show_item_position['colum'] = l:col

  let l:col = strwidth(l:fliter_words)
  let l:col  = 'cursor-' . l:col
  let l:opts = {'pos': 'topleft',
        \'zindex':2000,
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
        \'start_position': s:show_item_position,
        \'is_use_text_edit': v:false,
        \'original_position': {'line': line('.'), 
        \'colum': col('.'), 'line_content':getline('.')},
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
      if IsInList(j, l:point)
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

function! ECY#completion#ExpandSnippet() abort
"{{{ this function will not tirgger when there are no UltiSnips plugin.
  
  if ECY#completion#IsMenuOpen() 
    call ECY#completion#Close('force_to_close')
    " we can see that we require every item of completion must contain full
    " infos which is a dict with all key.
    if g:has_floating_windows_support == 'vim' && 
          \g:ECY_use_floating_windows_to_be_popup_windows
      let l:selecting_item_nr = 
            \g:ECY_current_popup_windows_info['selecting_item']
      if l:selecting_item_nr != 0
        let l:item_info = 
              \g:ECY_current_popup_windows_info['items_info'][l:selecting_item_nr - 1]
        let l:user_data_index    = l:selecting_item_nr - 1
        let l:item_kind          = l:item_info['kind']
        let l:item_name_selected = l:item_info['word']
      endif
    elseif g:has_floating_windows_support == 'neovim' && 
          \g:ECY_use_floating_windows_to_be_popup_windows
      " TODO
    else
      let l:item_kind          = v:completed_item['kind']
      let l:user_data_index    = v:completed_item['user_data']
      let l:item_name_selected = v:completed_item['word']
    endif

    " the user_data_index is a number that can index the g:ECY_completion_data which is
    " a dict to get more than just a string msg.
    try
      " maybe, some item have no snippet. so we try.
      let l:snippet   = g:ECY_current_popup_windows_info['items_info'][l:user_data_index]['snippet']
      call UltiSnips#Anon(l:snippet,l:item_name_selected,'have no desriction','w')
      return ''
    catch
    endtry

    try
      if l:item_kind == '[Snippet]'
        call UltiSnips#ExpandSnippet() 
        return ''
      endif
    catch
    endtry
  endif

  call ECY#utils#SendKeys(g:ECY_expand_snippets_key)
  return ''
"}}}
endfunction

function! s:SetUpCompleteopt() abort 
"{{{
  " can't format here:
  if g:has_floating_windows_support == 'vim' && 
        \g:ECY_use_floating_windows_to_be_popup_windows == v:true
    " use ours popup windows
    set completeopt-=menuone
    set completeopt+=menu
  else
    set completeopt-=menu
    set completeopt+=menuone
  endif
  set completeopt-=longest
  set shortmess+=c
  set completefunc=ECY#completion#Func
"}}}
endfunction

function! ECY#completion#Func(findstart, base) abort 
"{{{
  if a:findstart
    return s:show_item_position " a number
  endif
  return {'words': s:show_item_list}
"}}}
endfunction

fun! s:DoCompletion_old_school(context)
"{{{
  " a complete item in vim look like this and must be string.
  " so we have to use a triky way to do more thing.

  let l:items_info = a:context['show_list']
  let g:ECY_current_popup_windows_info['items_info'] = a:context['show_list']
  let l:fliter_words = a:context['filter_key']
  let s:show_item_position = len(a:context['prev_key']) - len(a:context['filter_key'])

  let i = 0
  let s:show_item_list = []

  for item in l:items_info
    let results_format = {'abbr': ECY#utils#GetValue(item, 'abbr', ''),
          \'word': ECY#utils#GetValue(item, 'word', ''),
          \'kind': ECY#utils#GetValue(item, 'kind', ''),
          \'menu': ECY#utils#GetValue(item, 'menu', ''),
          \'info': ECY#utils#GetValue(item, 'info', ''),
          \'user_data': string(i)}

    call add(s:show_item_list, l:results_format)
    let i += 1
  endfor

  call ECY#utils#SendKeys("\<C-X>\<C-U>\<C-P>")
"}}}
endf

fun! ECY#completion#Open(context)
"{{{
  if (g:popup_windows_is_selecting || len(a:context['filter_key']) <= g:ECY_triggering_length) 
        \&& !a:context['must_show']
    return
  endif

  if ECY#utils#GetCurrentBufferPath() != a:context['params']['buffer_path'] 
        \|| ECY#rpc#rpc_event#GetBufferIDNotChange() != a:context['params']['buffer_id']
        \|| len(a:context['show_list']) == 0
        \|| mode() == 'n'
    return
  endif

  call s:MapSelecting()

  if g:has_floating_windows_support == 'vim' 
        \&& g:ECY_use_floating_windows_to_be_popup_windows
    call s:DoCompletion_vim(a:context)
  elseif g:has_floating_windows_support == 'neovim'
        \&& g:ECY_use_floating_windows_to_be_popup_windows
    "TODO
  else " has no
    call s:DoCompletion_old_school(a:context)
  endif
  let l:start = a:context['params']['time_stamp']
  let g:abc = reltimefloat(reltime()) - l:start
"}}}
endf

function! ECY#completion#Close(...) abort
"{{{
  if g:popup_windows_is_selecting && a:0 == 0
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
  call ECY#preview_windows#Close()
  call s:RecoverIndent()
"}}}
endfunction

function! ECY#completion#IsMenuOpen() abort
"{{{
  if g:ECY_use_floating_windows_to_be_popup_windows == v:true
    if g:has_floating_windows_support == 'vim'
      if g:ECY_use_floating_windows_to_be_popup_windows == v:false
        return pumvisible()
      endif
      if s:popup_windows_nr != -1
        return v:true
      endif
      return v:false
    elseif g:has_floating_windows_support == 'neovim'
      "TODO
    endif
  else
    return pumvisible()
  endif
"}}}
endfunction

function! s:CompleteLine(bufnr, start, end, content) abort
"{{{
   let l:cursor_pos = getcurpos()
   let l:start_line = a:start['line'] + 1
   let l:end_line = a:end['line'] + 1
   let l:replace_list = split(a:content, "\n")

   let l:start_line_content = getbufline(a:bufnr, l:start_line, l:start_line)[0]
   if a:start['colum'] == 0
      let l:start_line_content = ""
   else
      let l:start_line_content = l:start_line_content[0: a:start['colum'] - 1]
   endif

   let l:end_line_content = getbufline(a:bufnr, l:end_line, l:end_line)[0]
   let l:end_line_content = l:end_line_content[a:end['colum']:]

   let l:replace_list[0] = l:start_line_content . l:replace_list[0]

   let l:replace_list[len(l:replace_list) - 1] = l:replace_list[len(l:replace_list) - 1] . l:end_line_content

   call ECY#utils#Replace(a:bufnr, l:start_line - 1, l:end_line - 1, l:replace_list)
   call cursor([l:end_line, a:start['colum'] + len(a:content) + 1])
   return l:replace_list
"}}}
endfunction

function! s:SelectItems_vim(next_or_pre) abort
"{{{
  if a:next_or_pre == 0
    let l:round = 1
  else
    let l:round = -1
  endif
  let l:start_colum = g:ECY_current_popup_windows_info['start_position']['colum']

  " loop
  let l:items_info       = g:ECY_current_popup_windows_info['items_info']
  let l:current_item     = g:ECY_current_popup_windows_info['selecting_item']
  let l:showing_item_len = len(l:items_info)
  let l:next_item        = (l:current_item + l:round) % (l:showing_item_len + 1)
  if l:next_item == -1
    let l:next_item = l:showing_item_len
  endif
  let g:ECY_current_popup_windows_info['selecting_item'] = l:next_item

  if l:next_item == 0
    let l:to_complete =  g:ECY_current_popup_windows_info['keyword_cache']
    let l:info = {}
    " don't need to hightlight at here
  else
    let l:to_complete =  l:items_info[l:next_item - 1]['word']

    let l:exe = "call prop_clear(". l:next_item .")"
    call win_execute(s:popup_windows_nr, l:exe)
    let l:info = l:items_info[l:next_item - 1]
    let l:temp = len(l:info['abbr'] . l:info['kind'])
    let l:point = l:info['match_point']
    let i = 0
    while i < g:ECY_current_popup_windows_info['floating_windows_width']
      if ECY#utils#GetCurrentBufferPath(i, l:point)
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
    let l:info = l:items_info[l:current_item - 1]
    let l:temp = len(l:info['abbr'].l:info['kind'])
    let l:point = l:info['match_point']
    let i = 0
    while i < g:ECY_current_popup_windows_info['floating_windows_width']
      if IsInList(i, l:point)
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

   if g:ECY_current_popup_windows_info['is_use_text_edit']
     call setbufline(bufnr(), line('.'), 
         \[g:ECY_current_popup_windows_info['original_position']['line_content']])
     call cursor([line('.'), 
           \g:ECY_current_popup_windows_info['original_position']['colum']
           \])
     let g:ECY_current_popup_windows_info['is_use_text_edit'] = v:false
  endif

  if has_key(l:info, 'completion_text_edit') && l:next_item != 0
     let l:start_colum = l:info['completion_text_edit']['start']['colum']
     call cursor([line('.'), l:info['completion_text_edit']['end']['colum'] + 1])
     let g:ECY_current_popup_windows_info['is_use_text_edit'] = v:true
  endif


  let l:start_colum += 1

  call complete(l:start_colum, [l:to_complete])
  return

  return
  if has_key(l:info, 'completion_text_edit')
    call s:CompleteLine(bufnr(), 
          \l:info['completion_text_edit']['start'], 
          \l:info['completion_text_edit']['end'],
          \l:to_complete)
  else
    " this function will trigger the insert event, and we don't want it to 
    " be triggered while completing.
    " IMPORTANCE: when comment this function, vim will not highlight the
    " selected item, because we filter the key of <Tab> that is selecting
    " mapping, then the s:isSelecting in ECY_main.vim can not be reset.
    call complete(l:start_colum + 1,[l:to_complete])
  endif


"}}}
endfunction

function! ECY#completion#SelectItems(next_or_prev, send_key) abort
"{{{
  if !ECY#completion#IsMenuOpen()
    call ECY#utils#SendKeys(a:send_key)
  else
    if g:ECY_use_floating_windows_to_be_popup_windows 
          \&& g:has_floating_windows_support == 'vim'
      let g:popup_windows_is_selecting = v:true
      call ECY#preview_windows#Close()
      call s:DisableIndent()
      call s:SelectItems_vim(a:next_or_prev)
    elseif g:has_floating_windows_support == 'neovim'
      "TODO
    endif
    call ECY#preview_windows#Open()
  endif

  call s:ItemSelectedCallback()
  return ''
"}}}
endfunction

function! s:ItemSelectedCallback() abort
"{{{ event callback
  try
    if g:ECY_use_floating_windows_to_be_popup_windows == v:true
      let l:selecting = g:ECY_current_popup_windows_info['selecting_item']
    else
      let l:selecting = str2nr(v:completed_item['user_data'])
      let l:selecting += 1
    endif
    if l:selecting != 0
      let l:selecting -= 1
      let l:ECY_item_index = g:ECY_current_popup_windows_info['items_info'][l:selecting]['ECY_item_index']
      let l:params = {
                    \'buffer_path': ECY#utils#GetCurrentBufferPath(), 
                    \'buffer_position': ECY#utils#GetCurrentLineAndPosition(), 
                    \'ECY_item_index': l:ECY_item_index, 
                    \'buffer_id': ECY#rpc#rpc_event#GetBufferIDNotChange()
                    \}
      call ECY#rpc#rpc_event#call({'event_name': 'OnItemSeleted', 'params': l:params})
    endif
  catch 
  endtry
"}}}
endfunction

function! s:SaveIndent() abort
"{{{
  if !exists('b:indentexpr_temp')
    let b:indentexpr_temp = &indentexpr
  endif
"}}}
endfunction

function! s:DisableIndent() abort
"{{{ DisableIndent temporally.
  call s:SaveIndent()
  let &indentexpr = ''
"}}}
endfunction

function! s:RecoverIndent() abort
"{{{
  if exists('b:indentexpr_temp')
    let &indentexpr = b:indentexpr_temp
  endif
"}}}
endfunction

function! s:MapSelecting() abort
"{{{
  try
    if g:ECY_use_floating_windows_to_be_popup_windows == v:false
      
      exe printf('imap <expr> %s pumvisible() ? "\<C-n>" : "\%s"', 
            \g:ECY_select_items[0], g:ECY_select_items[0])    
      exe printf('imap <expr> %s pumvisible() ? "\<C-n>" : "\%s"', 
            \g:ECY_select_items[1], g:ECY_select_items[1])    
    else
      exe 'imap <silent> ' . g:ECY_select_items[0].' <C-R>=ECY#completion#SelectItems(0,"\' . g:ECY_select_items[0] . '")<CR>'
      exe 'imap <silent> ' . g:ECY_select_items[1].' <C-R>=ECY#completion#SelectItems(1,"\' . g:ECY_select_items[1] . '")<CR>'
    endif

    exe 'imap <silent> ' . g:ECY_expand_snippets_key. ' <C-R>=ECY#completion#ExpandSnippet()<cr>'
  catch 
  endtry
"}}}
endfunction

fun! ECY#completion#Init()
"{{{
  let g:ECY_expand_snippets_key
        \= get(g:,'ECY_expand_snippets_key','<cr>')

  let g:ECY_select_items
        \= get(g:, 'ECY_select_items',['<tab>','<s-tab>'])

  let g:ECY_triggering_length
        \= get(g:,'ECY_triggering_length',1)

  let s:popup_windows_nr = -1
  let g:popup_windows_is_selecting = v:false

  call ECY#utils#DefineColor('ECY_floating_windows_normal_matched', 'guifg=#945596	guibg=#073642	ctermfg=red	  ctermbg=darkBlue')
  call ECY#utils#DefineColor('ECY_floating_windows_normal', 'guifg=#839496	guibg=#073642	ctermfg=white	ctermbg=darkBlue')
  call ECY#utils#DefineColor('ECY_floating_windows_seleted_matched', 'guifg=#FFFF99	guibg=#586e75	ctermfg=red	ctermbg=Blue')
  call ECY#utils#DefineColor('ECY_floating_windows_seleted', 'guifg=#eee8d5	guibg=#586e75	ctermfg=white	ctermbg=Blue')

  augroup ECY_completion
    autocmd!
    autocmd TextChangedI  * call ECY#completion#Close()
    autocmd InsertLeave   * call ECY#completion#Close()
    " if g:ECY_use_floating_windows_to_be_popup_windows == v:false
    "   autocmd CompleteDone   * call s:ItemSelectedCallback()
    " endif
  augroup END

  call s:MapSelecting()

  exe 'let g:ECY_expand_snippets_key = "\'.g:ECY_expand_snippets_key.'"'

  let s:show_item_position = 0
  let s:show_item_list = []
  let g:ECY_current_popup_windows_info = {}
  call s:SetUpCompleteopt()
"}}}
endf
