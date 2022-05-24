" Author: Jimmy Huang (1902161621@qq.com)
" License: WTFPL
 
function ECY#diagnostics#Init() abort
"{{{ var init
  let g:ECY_enable_diagnostics
        \= ECY#engine_config#GetEngineConfig('ECY', 'diagnostics.enable')

  if !g:ECY_enable_diagnostics
    return
  endif

  hi ECY_diagnostics_highlight  term=undercurl gui=undercurl guisp=DarkRed cterm=underline
  let g:ECY_diagnostics_highlight = ECY#engine_config#GetEngineConfig('ECY', 'diagnostics.text_highlight')

  hi ECY_erro_sign_highlight  guifg=red	    ctermfg=red	
  hi ECY_warn_sign_highlight  guifg=yellow	ctermfg=yellow
  let g:ECY_erro_sign_highlight = ECY#engine_config#GetEngineConfig('ECY', 'diagnostics.erro_sign_highlight')
  let g:ECY_warn_sign_highlight = ECY#engine_config#GetEngineConfig('ECY', 'diagnostics.warn_sign_highlight')

  " 1 means ask diagnostics when there are changes not including user in insert mode, trigger by DoCompletion()
  " 2 means ask diagnostics when there are changes including user in insert mode, trigger by OnBufferTextChanged().
  let g:ECY_is_update_diagnostics_in_insert_mode
        \= ECY#engine_config#GetEngineConfig('ECY', 'diagnostics.update_diagnostics_in_insert_mode')

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
  let s:sign_id_dict = {}
  let s:showing_winid = -1
  let g:ECY_diagnostics_hl = {}
  let s:current_diagnostics = {}
  let g:ECY_diagnostics_items_all = []
  let g:ECY_diagnostics_items_with_engine_name = {'nothing': []}
  " user don't want to update diagnostics in insert mode, but engine had
  " returned diagnostics, so we cache it and update after user leave insert
  " mode.


  call s:SetUpEvent()
  " call s:SetUpPython()

  let g:ECY_key_to_show_current_line_diagnostics = ECY#engine_config#GetEngineConfig('ECY', 'diagnostics.key_to_show_current_line_diagnostics')
  let g:ECY_key_to_show_next_diagnostics = ECY#engine_config#GetEngineConfig('ECY', 'diagnostics.key_to_show_next_diagnostics')
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
  engine_name = vim.eval('ECY#engine#GetBufferEngineName()')
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
  let l:engine_name = ECY#engine#GetBufferEngineName()
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
  let l:current_engine = ECY#engine#GetBufferEngineName()
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

function! s:CloseDiagnosisPopupWindows() abort
"{{{
  if s:showing_winid == -1
    return
  endif
  call s:popup_obj._close()
  let s:showing_winid = -1
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

  let s:popup_obj = easy_windows#new()

  let s:showing_winid = s:popup_obj._open(l:text, {
        \'at_cursor': 1,
        \'use_border': 1,
        \'exit_cb': function('s:PopupClosed'),
        \'x': easy_windows#get_cursor_screen_x() + 1,
        \'y': easy_windows#get_cursor_screen_y() + 1,
        \'syntax': 'ECY_diagnostics'})
  call s:popup_obj._align_width()
  call s:popup_obj._align_height()
"}}}
endfunction

function! s:PopupClosed() abort
  let s:showing_winid = -1
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

function! ECY#diagnostics#CleanAllSignHighlight() abort
"{{{ should be called after text had been changed.
  if !g:ECY_enable_diagnostics
    return
  endif

  let l:current_path = ECY#utils#GetCurrentBufferPath()

  for path in keys(g:ECY_diagnostics_hl)
    if path != l:current_path
      continue
    endif

    for hl_id in g:ECY_diagnostics_hl[path]
      call ECY#utils#UnHighlightRange(hl_id)
    endfor
  endfor

  let g:ECY_diagnostics_hl[l:current_path] = []
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
  catch 
  endtry

  if a:current_buffer_path == a:path
    let l:temp = ECY#utils#HighlightRange(a:position['range'], 'ECY_diagnostics_highlight')
    call add(g:ECY_diagnostics_hl[a:path], l:temp)
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

  if g:ECY_is_update_diagnostics_in_insert_mode == v:false && mode() == 'i'
    " don't want to update diagnostics in insert mode
    return
  endif

  let l:engine_name = ECY#engine#GetBufferEngineName()

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
    let s:showing_winid = -1
    let g:ECY_diagnostics_items_all = []
    let g:ECY_diagnostics_items_with_engine_name = {}
  endif
  call ECY#utils#echo('[ECY] Diagnosis status: ' . l:status)
"}}}
endfunction

function! ECY#diagnostics#ShowSelecting(is_current_engine) abort
"{{{
  let l:res = []
  let l:current_engine = ECY#engine#GetBufferEngineName()

  let l:temp = []
  if a:is_current_engine && has_key(g:ECY_diagnostics_items_with_engine_name, l:current_engine)
    let l:temp = g:ECY_diagnostics_items_with_engine_name[l:current_engine]
  else
    for item in keys(g:ECY_diagnostics_items_with_engine_name)
      call extend(l:temp, g:ECY_diagnostics_items_with_engine_name[item])
    endfor
  endif

  for item in l:temp
    let l:msg = join(item['diagnostics'], " ")
    let l:kind = item['kind'] == 1 ? 'Error' : 'Warn'
    let l:pos = item['position']['range']
    let l:pos = printf("[L-%s, C-%s]", l:pos['start']['line'], l:pos['start']['colum'])
    let l:kind_color = item['kind'] == 1 ? 'ErrorMsg' : 'WarningMsg'
    call add(l:res, {'abbr': [
          \{'value': l:kind, 'hl': l:kind_color}, {'value': l:msg}, {'value': l:pos, 'hl': 'LineNr'}], 
          \'path': item['file_path'], 'range': item['range']})
  endfor

  call ECY#qf#Open(l:res, {})
"}}}
endfunction

function! ECY#diagnostics#CopyCurrentLine() abort
"{{{
  if exists('s:popup_obj')
    return s:popup_obj._get_text()
  endif
  return ''
"}}}
endfunction

function! s:UpdateSignEvent(timer_id) abort 
"{{{
  if !g:ECY_enable_diagnostics
    call s:StopUpdateTimer()
    return
  endif
  if g:ECY_is_update_diagnostics_in_insert_mode == v:false && mode() == 'i'
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
          \ECY#engine#GetBufferEngineName())
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

