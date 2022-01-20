" Author: Jimmy Huang (1902161621@qq.com)
" License: WTFPL
 
function ECY#diagnostics#Init() abort
"{{{ var init
  let g:ECY_enable_diagnostics
        \= get(g:,'ECY_enable_diagnostics', v:true)

  if !g:ECY_enable_diagnostics
    return
  endif

  hi ECY_diagnostics_highlight  term=undercurl gui=undercurl guisp=DarkRed cterm=underline
  let g:ECY_diagnostics_highlight = get(g:,'ECY_diagnostics_highlight','ECY_diagnostics_highlight')

  hi ECY_erro_sign_highlight  guifg=red	    ctermfg=red	
  hi ECY_warn_sign_highlight  guifg=yellow	ctermfg=yellow
  let g:ECY_erro_sign_highlight = get(g:,'ECY_erro_sign_highlight', 'ECY_erro_sign_highlight')
  let g:ECY_warn_sign_highlight = get(g:,'ECY_warn_sign_highlight', 'ECY_warn_sign_highlight')

  " 1 means ask diagnostics when there are changes not including user in insert mode, trigger by DoCompletion()
  " 2 means ask diagnostics when there are changes including user in insert mode, trigger by OnBufferTextChanged().
  let g:ECY_is_update_diagnostics_in_insert_mode
        \= get(g:,'ECY_is_update_diagnostics_in_insert_mode', 1)
  if g:ECY_is_update_diagnostics_in_insert_mode == 2
    let g:ECY_is_update_diagnostics_in_insert_mode = v:true
  else
    let g:ECY_is_update_diagnostics_in_insert_mode = v:false
  endif

  " can not use sign_define()
  silent! execute 'sign define ECY_diagnostics_erro text=>> texthl=' . g:ECY_erro_sign_highlight
  silent! execute 'sign define ECY_diagnostics_warn text=>> texthl=' . g:ECY_warn_sign_highlight

  " call sign_define("ECY_diagnostics_erro", {
  "   \ "text" : ">>",
  "   \ "texthl" : g:ECY_erro_sign_highlight})
  " call sign_define("ECY_diagnostics_warn", {
  "   \ "text" : "!!",
  "   \ "texthl" : g:ECY_warn_sign_highlight})

  let s:supports_sign_groups = has('nvim-0.4.2') || exists('*sign_define')
  let s:supports_sign_groups = v:false
  let s:sign_id_dict                           = {}
  let s:current_diagnostics                    = {}
  let g:ECY_diagnostics_items_all              = []
  let g:ECY_windows_are_showing['diagnostics'] = -1
  let g:ECY_diagnostics_items_with_engine_name = {'nothing': []}
  " user don't want to update diagnostics in insert mode, but engine had
  " returned diagnostics, so we cache it and update after user leave insert
  " mode.


  call s:SetUpEvent()
  " call s:SetUpPython()

  let g:ECY_key_to_show_current_line_diagnostics = get(g:,'ECY_key_to_show_current_line_diagnostics', 'H')
  let g:ECY_key_to_show_next_diagnostics = get(g:,'ECY_key_to_show_next_diagnostics', '[j')
  exe 'nmap ' . g:ECY_key_to_show_current_line_diagnostics . ' :call ECY#diagnostics#ShowCurrentLineDiagnosis(v:false)<CR>'
  exe 'nmap ' . g:ECY_key_to_show_next_diagnostics . ' :call ECY#diagnostics#ShowNextDiagnosis(1)<CR>'
"}}}
endfunction

fun! s:InsertLeave()
"{{{
  if !g:ECY_enable_diagnostics
    return
  endif
  call ECY#diagnostics#FlushCurrentBufferUI()
"}}}
endf

function s:SetUpEvent() abort
  augroup ECY_Diagnosis
    autocmd InsertLeave * call s:InsertLeave()
  augroup END
endfunction

function s:SetUpPython() abort
"{{{
python3 <<endpython
import vim

def CalculateScreenSign(start, end):
  engine_name = vim.eval('ECY#switch_engine#GetBufferEngineName()')
  lists = "g:ECY_diagnostics_items_with_engine_name['" + engine_name + "']"
  lists = vim.eval(lists)
  file_path = vim.eval('ECY#utils#GetCurrentBufferPath()')
  results = []
  for item in lists:
    line = int(item['position']['line'])
    if item['file_path'] == file_path:
      if start <= line and end >= line:
        results.append(item)
  return results
endpython
"}}}
endfunction

function s:CalculateScreenSign(start, end) abort
"{{{
  let l:engine_name = ECY#switch_engine#GetBufferEngineName()
  let l:list = g:ECY_diagnostics_items_with_engine_name[l:engine_name]
  let l:file_path = ECY#utils#GetCurrentBufferPath()
  let l:res = []
  for item in l:list
    let l:line = item['position']['line']
    if item['file_path'] != l:file_path
      continue
    endif
    if a:start <= l:line && a:end >= l:line
      call add(l:res, item)
    endif
  endfor
  return l:res
"}}}
endfunction

function! ECY#diagnostics#ShowCurrentLineDiagnosis(is_triggered_by_event) abort
"{{{ show diagnostics msg in normal mode.
  if !g:ECY_enable_diagnostics || mode() != 'n'
    if !a:is_triggered_by_event
      call ECY#utils#echo("[ECY] Diagnosis had been turn off.")
    endif
    return ''
  endif
  let l:current_line_nr     = line('.')
  let l:current_col_nr      = col('.')
  let l:current_buffer_path = ECY#utils#GetCurrentBufferPath()
  call ECY#diagnostics#Show(l:current_buffer_path, l:current_line_nr,
        \l:current_col_nr, a:is_triggered_by_event)
  
  return '' " we should return ''
"}}}
endfunction

function! ECY#diagnostics#CurrentBufferErrorAndWarningCounts() abort
  let l:current_engine = ECY#switch_engine#GetBufferEngineName()
  if !has_key(g:ECY_diagnostics_items_with_engine_name, l:current_engine)
    return 0
  endif
  return len(g:ECY_diagnostics_items_with_engine_name[l:current_engine])
endfunction

function! ECY#diagnostics#Show(file_path, line, colum, is_triggered_by_event) abort
"{{{ show a popup windows and move to that position.
  if g:ECY_diagnostics_items_all == []
    call s:InitDiagnosisLists()
  endif

  let l:index_list = []
  let l:index = -1
  for item in g:ECY_diagnostics_items_all
    if a:file_path != item['file_path'] || a:line != item['position']['line']
      continue
    endif
    let l:index = item['index']
    call add(l:index_list, item)
  endfor

  if len(l:index_list) == 0
    if !a:is_triggered_by_event
      call ECY#utils#echo("[ECY] Diagnosis has nothing to show at current buffer line.")
    endif
    return
  endif

  let s:current_diagnostics              = {}
  let s:current_diagnostics['file_path'] = a:file_path
  let s:current_diagnostics['line']      = a:line
  let s:current_diagnostics['colum']     = a:colum
  let s:current_diagnostics['index']     = l:index

  call ECY#utils#MoveToBuffer(a:line, a:colum, a:file_path, 'current buffer')

  if g:has_floating_windows_support == 'vim'
    call s:ShowDiagnosis_vim(l:index_list)
  elseif g:has_floating_windows_support == 'nvim'
    " TODO
  else
    call s:ShowDiagnosis_all(l:index_list)
  endif
"}}}
endfunction

function! ECY#diagnostics#ShowNextDiagnosis(next_or_pre) abort
"{{{ show diagnostics msg in normal mode at current buffer. 
  let l:items_len = len(g:ECY_diagnostics_items_all)
  if l:items_len == 0
    call s:InitDiagnosisLists()
    let l:items_len = len(g:ECY_diagnostics_items_all)
    if l:items_len == 0
      call ECY#utils#echo("[ECY] Diagnosis has nothing to show at current buffer line.")
      return ''
    endif
  endif

  let l:file_path = ECY#utils#GetCurrentBufferPath()

  if s:current_diagnostics != {}
    let l:index = (s:current_diagnostics['index'] + a:next_or_pre) % l:items_len
    try
      let item = g:ECY_diagnostics_items_all[l:index]
      let l:file_path = item['file_path']
      let l:line = item['position']['line']
      let l:colum = item['position']['range']['start']['colum']
    catch 
      let s:current_diagnostics = {}
    endtry
  endif

  if s:current_diagnostics == {}
    for item in g:ECY_diagnostics_items_all
      if l:file_path == item['file_path']
        let l:line = item['position']['line']
        let l:colum = item['position']['range']['start']['colum']
        break
      endif
    endfor
    if !exists('l:line')
      call ECY#utils#echo("[ECY] Diagnosis has nothing to show at current buffer line.")
      return ''
    endif
  endif

  call ECY#diagnostics#Show(l:file_path, l:line, l:colum, v:true)
  return ''
"}}}
endfunction

function! g:Diagnosis_vim_cb(id, key) abort
  let g:ECY_windows_are_showing['diagnostics'] = -1
endfunction

function! s:CloseDiagnosisPopupWindows() abort
"{{{
  call quickui#preview#close()
  let g:ECY_windows_are_showing['diagnostics'] = -1
"}}}
endfunction

function! s:FormatInfo(diagnostics) abort
"{{{
  let l:res = []
  if type(a:diagnostics) == v:t_string
    " strings
    call add(l:res, '(' . a:diagnostics . ')')
  elseif type(a:diagnostics) == v:t_list
    " lists
    if len(a:diagnostics) == 1
      call add(l:res, '('.a:diagnostics[0].')')
    else
      let i = 0
      for item in a:diagnostics
        if i == 0
          call add(l:res, '('.item)
        else
          call add(l:res, item)
        endif
        let i += 1
      endfor
      call add(l:res, a:diagnostics[i - 1].')')
    endif
  endif
  return l:res
"}}}
endfunction

function! s:ShowDiagnosis_vim(index_list) abort
"{{{ 
  call s:CloseDiagnosisPopupWindows()
  let l:text = []
  for item in a:index_list
    if len(l:text) != 0
      call add(l:text, '----------------------------')
    endif
    let l:line = string(item['position']['line'])
    let l:colum = string(item['position']['range']['start']['colum'])
    let l:index = string(s:current_diagnostics['index'] + 1)
    let l:lists_len = string(len(g:ECY_diagnostics_items_all))
    let l:nr = printf('(%s/%s)', l:index, l:lists_len)
    if item['kind'] == 1
      let l:style = 'ECY_diagnostics_erro'
    else
      let l:style = 'ECY_diagnostics_warn'
    endif
    call add(l:text, printf('%s [L-%s, C-%s] %s', l:style, l:line, l:colum, l:nr))
    call extend(l:text, s:FormatInfo(item['diagnostics']))
  endfor

  let g:ECY_windows_are_showing['diagnostics'] = 
        \quickui#preview#display(l:text, {
          \'syntax': 'ECY_diagnostics', 
          \'number': 0,
          \'h':len(l:text)})
"}}}
endfunction

function! s:ShowDiagnosis_all(index_list) abort
"{{{ 
  let l:temp = '[ECY] '
  let i = 0
  for item in a:index_list
    let l:temp .= join(s:FormatInfo(item['diagnostics']), "\n")
    if i != 0
      let l:temp .= '|'
    endif
    let i += 1
  endfor
  call ECY#utils#echo(l:temp)
"}}}
endfunction

function! s:CalculatePosition(line, col, end_line, end_col) abort
"{{{
  " this was copy from ALE
    let l:MAX_POS_VALUES = 8
    let l:MAX_COL_SIZE = 1073741824 " pow(2, 30)
    if a:line >= a:end_line
        " For single lines, just return the one position.
        return [[[a:line, a:col, a:end_col - a:col + 1]]]
    endif

    " Get positions from the first line at the first column, up to a large
    " integer for highlighting up to the end of the line, followed by
    " the lines in-between, for highlighting entire lines, and
    " a highlight for the last line, up to the end column.
    let l:all_positions =
    \   [[a:line, a:col, l:MAX_COL_SIZE]]
    \   + range(a:line + 1, a:end_line - 1)
    \   + [[a:end_line, 1, a:end_col]]

    return map(
    \   range(0, len(l:all_positions) - 1, l:MAX_POS_VALUES),
    \   'l:all_positions[v:val : v:val + l:MAX_POS_VALUES - 1]',
    \)
"}}}
endfunction

function! ECY#diagnostics#HighlightRange(range, highlights) abort
"{{{ return a list of `matchaddpos` e.g. [match_point1, match_point2]
"a:range = {'start': { 'line': 5, 'colum': 23 },'end' : { 'line': 6, 'colum': 0 } }
"
"colum is 0-based, but highlight's colum is 1-based, so we add 1.
"ensure cursor in buffer you want to highlight before you call this function.

  " map like a loop
  call map(s:CalculatePosition(a:range['start']['line'],
          \a:range['start']['colum'] + 1,
          \a:range['end']['line'],
          \a:range['end']['colum'] + 1),
        \'matchaddpos(a:highlights, v:val)')
"}}}
endfunction

function! ECY#diagnostics#CleanAllSignHighlight() abort
"{{{ should be called after text had been changed.
  if !g:ECY_enable_diagnostics
    return
  endif
  for l:match in getmatches()
      if l:match['group'] =~# '^ECY_diagnostics'
          call matchdelete(l:match['id'])
      endif
  endfor
"}}}
endfunction

function! s:PlaceSignAndHighlight(position, diagnostics, items, style, path,
      \engine_name, current_buffer_path) abort
"{{{ place a sign in current buffer.
  " a:position = {'line': 10, 'range': {'start': { 'line': 5, 'colum': 23 },'end' : { 'line': 6, 'colum': 0 } }}
  " a:diagnostics = {'item':{'1':'asdf', '2':'sdf'}}
  if a:style == 1
    let l:style = 'ECY_diagnostics_erro'
  else
    let l:style = 'ECY_diagnostics_warn'
  endif
  let l:group_name = a:engine_name
  try
    call s:PlaceSign(a:engine_name, l:style, a:path, a:position['line'])
    " call sign_place(0,
    "        \l:group_name,
    "        \l:style, a:path,
    "        \{'lnum' : a:position['line']})
  catch 
  endtry
  if a:current_buffer_path == a:path
    call ECY#diagnostics#HighlightRange(a:position['range'], 'ECY_diagnostics_highlight')
  endif
"}}}
endfunction

function! s:PlaceSign(engine_name, style, path, line) abort
"{{{
  
  if s:supports_sign_groups
    let l:temp = 'sign place 454 line='.a:line.' group='.a:engine_name.' name='.a:style.' file='.a:path
  else
    let l:increment_id = s:sign_id_dict[a:engine_name]['increment_id'] + 1
    let s:sign_id_dict[a:engine_name]['increment_id'] = l:increment_id
    " l:increment_id will not exceed 45481. so we don't need to consider that id
    " will be invalid. why 454? it doesn't matter, and just a number.
    let l:increment_id = '454'.string(s:sign_id_dict[a:engine_name]['name_id'] ) . string(l:increment_id)
    call add(s:sign_id_dict[a:engine_name]['id_lists'] , {'sign_id': l:increment_id, 'file_path': a:path})
    let l:temp = 'sign place '.l:increment_id.' line='.a:line.' name='.a:style.' file='.a:path
  endif
  silent! execute l:temp
"}}}
endfunction

function! s:UnplaceAllSignByEngineName(engine_name) abort
"{{{
  if s:supports_sign_groups
    silent! execute 'sign unplace * group=' . a:engine_name
  else
    if !exists('s:sign_id_dict[a:engine_name]')
      let s:sign_id_dict[a:engine_name] = {'id_lists': [], 
            \'name_id': len(g:ECY_diagnostics_items_with_engine_name),
            \'increment_id': 1}
    endif
    for item in s:sign_id_dict[a:engine_name]['id_lists']
      silent! execute 'sign unplace '.item['sign_id'].' file=' . item['file_path']
    endfor
    let s:sign_id_dict[a:engine_name]['id_lists']     = []
    let s:sign_id_dict[a:engine_name]['increment_id'] = 1
  endif
"}}}
endfunction

function! s:PartlyPlaceSign_timer_cb(starts, ends, engine_name) abort
"{{{
  if !has_key(g:ECY_diagnostics_items_with_engine_name, a:engine_name)
    return
  endif
  let l:file_path = ECY#utils#GetCurrentBufferPath()
  let l:lists = s:CalculateScreenSign(a:starts, a:ends)
  call ECY#diagnostics#CleanAllSignHighlight()
  call s:UnplaceAllSignByEngineName(a:engine_name)
  for item in l:lists
    call s:PlaceSignAndHighlight(item['position'], 
          \item['diagnostics'],
          \item['items'], item['kind'],
          \item['file_path'],
          \a:engine_name,
          \l:file_path)
  endfor
"}}}
endfunction

function! s:UpdateDiagnosisByEngineName(msg) abort
  let l:engine_name = a:msg['engine_name']
  let g:ECY_diagnostics_items_with_engine_name[l:engine_name] = a:msg['res_list']
  let g:ECY_diagnostics_items_all = []
  let s:current_diagnostics = {}
endfunction

function! ECY#diagnostics#PartlyPlaceSign(msg) abort
  call s:StartUpdateTimer()
endfunction

function! ECY#diagnostics#FlushCurrentBufferUI() abort
"{{{

  if g:ECY_is_update_diagnostics_in_insert_mode == v:false && mode() != 'n'
    " don't want to update diagnostics in insert mode
    return
  endif

  let l:engine_name = ECY#switch_engine#GetBufferEngineName()

  if v:false
    call ECY#diagnostics#PartlyPlaceSign(a:msg)
    return
  else
    call s:StopUpdateTimer()
  endif
  " show sign.
  call s:UpdateSignLists(l:engine_name)
"}}}
endfunction

function! ECY#diagnostics#PlaceSign(msg) abort
"{{{Place Sign and highlight it. partly or all

  let l:engine_name = a:msg['engine_name']
  if !g:ECY_enable_diagnostics || l:engine_name == '' || type(a:msg) != 4 || 
        \!has_key(a:msg, 'res_list') || type(a:msg['res_list']) != v:t_list
    return
  endif

  call s:UpdateDiagnosisByEngineName(a:msg) " but don't show sign, just update variable.
  call ECY#diagnostics#FlushCurrentBufferUI()
"}}}
endfunction

function! ECY#diagnostics#ClearByEngineName(engine_name) abort
"{{{
  let g:ECY_diagnostics_items_with_engine_name[a:engine_name] = []
  call s:UpdateSignLists(a:engine_name)
"}}}
endfunction

function! s:UpdateSignLists(engine_name) abort
"{{{
  if !has_key(g:ECY_diagnostics_items_with_engine_name, a:engine_name)
    return
  endif
  call ECY#diagnostics#CleanAllSignHighlight()
  call s:UnplaceAllSignByEngineName(a:engine_name)
  let l:sign_lists = g:ECY_diagnostics_items_with_engine_name[a:engine_name]
  let l:file_path = ECY#utils#GetCurrentBufferPath()
  for item in l:sign_lists
    " item = {'items':[
    " {'name':'1', 'content': {'abbr': 'xxx'}},
    " {'name':'2', 'content': {'abbr': 'yyy'}}
    "  ],
    " 'position':{...}, 'diagnostics': 'strings'}

    call s:PlaceSignAndHighlight(item['position'], 
          \item['diagnostics'],
          \item['items'], item['kind'],
          \item['file_path'],
          \a:engine_name,
          \l:file_path)
  endfor
"}}}
endfunction

function! s:InitDiagnosisLists() abort
"{{{return lists
 let l:temp = []
 for [key, lists] in items(g:ECY_diagnostics_items_with_engine_name)
   if type(lists) != 3 " is not list
     continue
   endif
   call extend(l:temp, lists)
 endfor
 let g:ECY_diagnostics_items_all = l:temp
 let i = 0
 while i < len(g:ECY_diagnostics_items_all)
   let g:ECY_diagnostics_items_all[i]['index'] = i
   let i += 1
 endw
 return l:temp
"}}}
endfunction

function! ECY#diagnostics#ClearAllSign() abort
"{{{
  for [key, lists] in items(g:ECY_diagnostics_items_with_engine_name)
    call s:UnplaceAllSignByEngineName(key)
  endfor
"}}}
endfunction

function! ECY#diagnostics#Toggle() abort
"{{{
  let g:ECY_enable_diagnostics = (!g:ECY_enable_diagnostics)
  if g:ECY_enable_diagnostics
    let l:status = 'Active'
    call s:StartUpdateTimer()
  else
    let l:status = 'Disabled'
    call s:StopUpdateTimer()
    call ECY#diagnostics#CleanAllSignHighlight()
    call ECY#diagnostics#ClearAllSign()
    let s:current_diagnostics       = {}
    let g:ECY_windows_are_showing['diagnostics'] = -1
    let g:ECY_diagnostics_items_all = []
    let g:ECY_diagnostics_items_with_engine_name = {}
  endif
  call ECY#utils#echo('[ECY] Diagnosis status: ' . l:status)
"}}}
endfunction

function! ECY#diagnostics#ShowSelecting() abort
"{{{ show all
  call s:InitDiagnosisLists()
  call ECY#utility#StartLeaderfSelecting(g:ECY_diagnostics_items_all, 'ECY#diagnostics#Selecting_cb')
"}}}
endfunction

function! ECY#diagnostics#Selecting_cb(line, event, index, nodes) abort
"{{{
 let l:data = g:ECY_diagnostics_items_all
  let l:data  = l:data[a:index]
  if a:event == 'acceptSelection' || a:event == 'previewResult'
    let l:position = l:data['position']['range']['start']
    let l:path = l:data['file_path']
    call ECY#utils#MoveToBuffer(l:position['line'], 
          \l:position['colum'], 
          \l:path, 
          \'current buffer')
  endif
"}}}
endfunction

function! s:UpdateSignEvent(timer_id) abort 
"{{{
  if !g:ECY_enable_diagnostics
    call s:StopUpdateTimer()
    return
  endif
  if g:ECY_is_update_diagnostics_in_insert_mode == v:false && mode() != 'n'
    return
  endif
  let l:start = line('w0')
  let l:end = line('w$')
  let l:windows_nr = winnr()
  if l:start != s:windows_start || l:end != s:windows_end || s:windows_nr !=
        \l:windows_nr
    let s:windows_start = l:start
    let s:windows_end = l:end
    let s:windows_nr = l:windows_nr
    call s:PartlyPlaceSign_timer_cb(s:windows_start, s:windows_end,
          \ECY#switch_engine#GetBufferEngineName())
  endif
"}}}
endfunction

function! s:StartUpdateTimer() abort 
"{{{
  let s:windows_start = -1
  let s:windows_end = -1
  let s:windows_nr = -1
  " order matters
  call s:StopUpdateTimer()
  let s:update_timer_id = timer_start(1000, function('s:UpdateSignEvent'), {'repeat': -1})
"}}}
endfunction

function! s:StopUpdateTimer() abort 
  if exists('s:update_timer_id')
    if s:update_timer_id != -1
      call timer_stop(s:update_timer_id)
    endif
  endif
  let s:update_timer_id = -1
endfunction

